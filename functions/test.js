const admin = require('firebase-admin');
admin.initializeApp({ projectId: "demo-fairscale" });
const db = admin.firestore();
db.settings({
    host: '127.0.0.1:9100',
    ssl: false
});

async function run() {
    await db.collection("applications").add({
        name: "Test User",
        income: 50000,
        zipcode: "90210",
        gender: "Female",
        race: "Asian",
        status: "pending",
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Success");
}
run();
