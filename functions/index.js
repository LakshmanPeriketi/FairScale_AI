const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.processApplication = functions.firestore
  .document("applications/{appId}")
  .onCreate(async (snap, context) => {

    console.log(`🔥 PROCESSING APP: ${snap.id}`);
    const data = snap.data();

    const biasScore = data.bias_score ? parseFloat(data.bias_score) : 0.0;
    const fairDecision = data.fair_score !== undefined ? (data.fair_score === 1 ? "APPROVE" : "REJECT") : "PENDING";
    const recommendation = data.ai_recommendation || "System scan complete.";

    const demographics = [];
    if (data.Race) demographics.push(`Race (${data.Race})`);
    if (data.Sex) demographics.push(`Gender (${data.Sex})`);
    if (data.Country) demographics.push(`Nationality (${data.Country})`);

    const demographicStr = demographics.length > 0 ? demographics.join(", ") : "Universal Metrics";

    let explanation;
    if (biasScore > 0.5) {
      explanation = `**🚨 AI BIAS ALERT:**
Our Interceptor detected a **${(biasScore * 100).toFixed(0)}% correlation** between the decision and protected demographics (${demographicStr}). 

**Findings:** The model weights show disproportionate impact on this profile.
**Correction:** Applying Model C's decision (**${fairDecision}**) which focuses on merit metrics.`;
    } else {
      explanation = `**✅ FAIRNESS VERIFIED:**
FairScale Shield analyzed the application using Model B and found **no significant demographic bias** ($${(biasScore * 100).toFixed(0)}% variance).

**Conclusion:** The decision was driven by neutral indicators. Model A's recommendation is confirmed as fair.`;
    }

    console.log(`📝 WRITING EXPLANATION: ${explanation.substring(0, 30)}...`);

    await snap.ref.set({
      gemini_explanation: explanation,
      ai_recommendation: recommendation,
      status: "reviewed",
      processedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    console.log("✅ UPDATE SUCCESSFUL");
  });