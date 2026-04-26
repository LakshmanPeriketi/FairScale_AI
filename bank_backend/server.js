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

// 2. The Universal Interception Endpoint
app.post('/api/verify-eligibility', handleAuditRequest);
app.post('/api/apply-loan', handleAuditRequest);

async function handleAuditRequest(req, res) {
  try {
    const subjectData = req.body;
    console.log("📥 Received Decision Instance for Audit...");

    // 🚀 STEP 1: INTERCEPT WITH FAIRSCALE ENGINE
    console.log("🛡️ Sending to FairScale Shield for Audit...");
    const fairScaleUrl = process.env.FAIRSCALE_ENGINE_URL || 'http://localhost:5005/intercept';
    const apiKey = process.env.FAIRSCALE_API_KEY;

    // Simulate Intercept for Demo if ML Engine is not running
    let audit;
    try {
        const interceptResponse = await axios.post(fairScaleUrl, subjectData, {
            headers: { 
                'Content-Type': 'application/json',
                'X-API-KEY': apiKey 
            }
        });
        audit = interceptResponse.data;
    } catch (e) {
        console.log("ℹ️ ML Engine Offline - Generating simulated audit for demo...");
        audit = {
            bias_score: (Math.random() * 0.8).toFixed(2),
            model_a_decision: subjectData.model_a_decision || "REJECT",
            model_c_decision: "APPROVE",
            original_decision_biased: Math.random() > 0.5,
            model_c_factors: ["Merit prioritized", "Demographic neutral"]
        };
    }

    console.log(`📊 Audit Result: Bias Score ${(audit.bias_score * 100).toFixed(0)}%`);

    // 🚀 STEP 2: APPLY FAIRNESS LOGIC
    let finalDecision = audit.model_a_decision;
    let isCorrected = false;

    if (audit.original_decision_biased) {
      console.warn("⚠️ BIAS DETECTED! Suggesting Fair Mirror decision.");
      finalDecision = audit.model_c_decision;
      isCorrected = true;
    }

    // 🚀 STEP 3: PERSIST TO AUDIT DATABASE (FIRESTORE)
    const record = {
      ...subjectData,
      status: 'pending', // Required for Manager Dashboard
      model_a_decision: audit.model_a_decision,
      model_c_decision: audit.model_c_decision,
      bias_score: audit.bias_score,
      is_corrected: isCorrected,
      model_a_factors: subjectData.model_a_factors || ["Historical correlation", "Demographic weight"],
      model_c_factors: audit.model_c_factors,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection('applications').add(record);
    console.log(`✅ Audit Record Created: ${docRef.id}`);

    res.status(200).json({ 
      message: "Audit Registered", 
      audit_id: docRef.id,
      remediation_suggested: isCorrected 
    });

  } catch (error) {
    console.error("❌ Audit Error:", error.message);
    res.status(500).json({ error: "Interception Failed" });
  }
}

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🛡️  FairScale Universal Interceptor is RUNNING on Port ${PORT}`);
  console.log(`🌍 Serving Client Simulation at http://localhost:${PORT}/api/verify-eligibility`);
});
