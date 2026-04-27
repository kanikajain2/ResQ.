import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/incident_model.dart';

class ResponderPortalScreen extends StatelessWidget {
  final String incidentId;
  const ResponderPortalScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: StreamBuilder<IncidentModel>(
        stream: firestore.streamIncident(incidentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded,
                      color: Colors.white24, size: 80),
                  const SizedBox(height: 16),
                  const Text("BRIEF NOT FOUND",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("The incident ID may be invalid or expired.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text("GO BACK",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          final incident = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("OFFICIAL RESPONDER BRIEF",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text("Room ${incident.roomNumber}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                      Text(
                          "${incident.type.toUpperCase()} — Severity ${incident.severity}/5",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle,
                                color: Colors.greenAccent, size: 8),
                            const SizedBox(width: 6),
                            Text("LIVE — ${incident.status.toUpperCase()}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Summary
                      _buildCard(
                        icon: Icons.psychology,
                        title: "AI Situation Summary",
                        content: incident.aiSummary ?? incident.description,
                      ),
                      const SizedBox(height: 16),

                      // Location info
                      _buildCard(
                        icon: Icons.location_on,
                        title: "Location",
                        content: "Room ${incident.roomNumber}\n"
                            "Floor ${incident.floor?.isNotEmpty == true ? incident.floor : 'Unknown'}\n"
                            "Wing ${incident.wing?.isNotEmpty == true ? incident.wing : 'Unknown'}",
                      ),
                      const SizedBox(height: 16),

                      // Incident type card
                      _buildCard(
                        icon: Icons.warning_amber_rounded,
                        title: "Incident Type",
                        content: incident.type.toUpperCase(),
                      ),
                      const SizedBox(height: 16),

                      // Post incident report if available
                      if (incident.postIncidentReport != null &&
                          incident.postIncidentReport!.isNotEmpty)
                        _buildCard(
                          icon: Icons.summarize,
                          title: "Post-Incident Report",
                          content: incident.postIncidentReport!,
                        ),
                      const SizedBox(height: 16),

                      // Assigned responder + call button
                      if (incident.assignedResponderName?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("On-site Contact",
                                        style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11)),
                                    Text(
                                        incident.assignedResponderName ??
                                            'Assigned Staff',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                onPressed: () {
                                  // Copy name to clipboard as fallback
                                  Clipboard.setData(ClipboardData(
                                      text: incident.assignedResponderName ??
                                          'Staff'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Contact name copied")));
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text("Copy"),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Expiry note
                      Center(
                        child: Text(
                          "This brief is live and updates automatically",
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Incident ID: $incidentId",
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 4),
                Text(content,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
