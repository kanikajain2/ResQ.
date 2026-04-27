const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

exports.generateBrief = onCall(async (request) => {
  // Generates a brief for first responders via dynamic link
  const { incidentId } = request.data;
  
  // Mock Dynamic Link creation logic
  const mockLink = `https://resq.page.link/incident/${incidentId}`;
  
  return {
    link: mockLink,
  };
});
