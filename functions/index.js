const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.processApplication = functions.firestore
  .document("applications/{appId}")
  .onCreate(async (snap, context) => {

    console.log("🔥 FUNCTION TRIGGERED");

    const data = snap.data();

    // MODEL A (biased / original)
    const modelA = data.income > 50000 ? "Approved" : "Rejected";

    // MODEL B (bias detector)
    const modelB_biasFlag = data.zipCode ? "Bias Suspected" : "No Bias";

    // MODEL C (fair model - ignores protected attributes)
    const modelC = data.income > 25000 ? "Approved" : "Rejected";

    // Gemini-style explanation (simulated)
    const explanation = `Model A gave ${modelA}. 
Model C suggests ${modelC} based on valid features like income. 
Potential bias detected due to zipCode influence.`;

    await snap.ref.update({
      modelA_decision: modelA,
      modelB_biasFlag: modelB_biasFlag,
      modelC_decision: modelC,
      bias_score: Math.random().toFixed(2),
      gemini_explanation: explanation,
      status: "reviewed",
      processedAt: new Date()
    });

    console.log("✅ DONE");
  });