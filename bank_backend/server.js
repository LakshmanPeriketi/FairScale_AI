const express = require('express');
const cors = require('cors');
const axios = require('axios');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// 1. Initialize Firebase Admin (Connect to Local Emulator)
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:9100";
admin.initializeApp({
  projectId: "demo-fairscale"
});

const db = admin.firestore();

// 2. The Interception Endpoint for the Bank Website
app.post('/api/apply-loan', async (req, res) => {
  try {
    const applicantData = req.body;
    console.log("📥 Received Loan Application from Frontend...");

    // 🚀 STEP 1: INTERCEPT WITH FAIRSCALE ENGINE
    console.log("🛡️ Sending to FairScale Shield for Audit...");
    const fairScaleUrl = process.env.FAIRSCALE_ENGINE_URL || 'http://localhost:5005/intercept';
    const apiKey = process.env.FAIRSCALE_API_KEY;

    const interceptResponse = await axios.post(fairScaleUrl, applicantData, {
      headers: { 
        'Content-Type': 'application/json',
        'X-API-KEY': apiKey 
      }
    });
    const audit = interceptResponse.data;

    console.log(`📊 Audit Result: Bias Score ${audit.bias_score * 100}%`);

    // 🚀 STEP 2: APPLY FAIRNESS LOGIC
    let finalDecision = audit.model_a_decision;
    let isCorrected = false;

    if (audit.original_decision_biased) {
      console.warn("⚠️ BIAS DETECTED! Overriding with Fair Mirror decision.");
      finalDecision = audit.model_c_decision;
      isCorrected = true;
    }

    // 🚀 STEP 3: PERSIST TO BANK DATABASE (FIRESTORE)
    const applicationRecord = {
      ...applicantData,
      status: 'pending', // CRITICAL: Required for Manager Dashboard "Live Feed"
      original_model_decision: audit.model_a_decision,
      fairscale_decision: audit.model_c_decision,
      final_status: finalDecision,
      bias_score: audit.bias_score,
      is_corrected: isCorrected,
      audit_factors: audit.model_c_factors,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      interceptor_version: "v1.0-node"
    };

    const docRef = await db.collection('applications').add(applicationRecord);

    console.log(`✅ Application Saved. ID: ${docRef.id} | Result: ${finalDecision}`);

    // 🚀 STEP 4: RESPOND TO FRONTEND
    res.json({
      status: "success",
      application_id: docRef.id,
      decision: finalDecision,
      is_corrected: isCorrected,
      audit_summary: audit.message
    });

  } catch (error) {
    console.error("❌ Backend Error:", error.message);
    res.status(500).json({ status: "error", message: "Interception failed at bank backend level." });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🏦 Bank Backend is RUNNING on Port ${PORT}`);
  console.log(`🛡️  Shielded by FairScale ML Engine at ${process.env.FAIRSCALE_ENGINE_URL || 'http://localhost:5005'}`);
});
