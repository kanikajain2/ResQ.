const { onDocumentCreated, onDocumentWritten, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ maxInstances: 10, region: "us-central1" });

exports.triageIncident = onDocumentCreated("incidents/{incidentId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;
  const incidentId = event.params.incidentId;
  const data = snapshot.data();
  
  // Gemini AI Triage Hook
  const mockSeverity = Math.floor(Math.random() * 5) + 1; // 1-5
  const mockSummary = "AI Summary: " + data.description;
  const mockTeam = mockSeverity > 3 ? "security" : "housekeeping";
  
  await admin.firestore().collection("incidents").doc(incidentId).update({
    severity: mockSeverity,
    aiSummary: mockSummary,
    suggestedTeam: mockTeam,
    status: 'triaged'
  });
  
  // Trigger High-Priority FCM Alert
  const payload = {
    notification: {
      title: `URGENT: Level ${mockSeverity} Incident in Room ${data.roomNumber}`,
      body: mockSummary,
    },
    topic: "staff_alerts"
  };
  await admin.messaging().send(payload);
  console.log(`Incident ${incidentId} triaged & alert sent.`);
});

exports.escalateIncident = onSchedule("every 1 minutes", async (event) => {
  const db = admin.firestore();
  const threshold = new Date(Date.now() - 60000); 
  const snapshot = await db.collection("incidents")
    .where("status", "==", "triaged")
    .where("createdAt", "<", threshold)
    .get();
    
  if (snapshot.empty) return;
  
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    const newCount = (data.escalationCount || 0) + 1;
    batch.update(doc.ref, { escalationCount: newCount });
  });
  await batch.commit();
});

exports.generatePostIncidentReport = onDocumentUpdated("incidents/{incidentId}", async (event) => {
  const after = event.data.after.data();
  const before = event.data.before.data();
  
  if (before.status !== 'resolved' && after.status === 'resolved') {
    // Generate AI report
    const mockReport = `Post Incident Report for ${event.params.incidentId}: Incident resolved successfully in ${after.escalationCount} escalations. Recommendations: Review response times.`;
    await admin.firestore().collection("incidents").doc(event.params.incidentId).update({
      postIncidentReport: mockReport
    });
    console.log(`Generated report for ${event.params.incidentId}`);
  }
});

exports.translateMessage = onCall(async (request) => {
  const text = request.data.text;
  const targetLanguage = request.data.targetLanguage || 'en';
  // Mock translate
  return { translatedText: `[${targetLanguage}] ${text}` };
});

exports.generateBrief = require("./functions/generateBrief");
