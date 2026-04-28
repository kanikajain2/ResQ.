import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/incident_model.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String id;
  const IncidentDetailScreen({super.key, required this.id});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  bool _guestSafe = true;
  bool _areaClear = true;
  bool _servicesNotified = true;

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: StreamBuilder<IncidentModel>(
          stream: firestore.streamIncident(widget.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5267)));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Incident not found", style: TextStyle(color: Colors.white)));
            }
            final incident = snapshot.data!;

            return FutureBuilder<StaffModel?>(
              future: auth.currentUser?.uid != null 
                  ? firestore.getStaffProfile(auth.currentUser!.uid) 
                  : Future.value(null),
              builder: (context, staffSnapshot) {
                final currentStaff = staffSnapshot.data;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(incident),
                      const SizedBox(height: 16),
                      
                      // Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildAiSummary(incident),
                                const SizedBox(height: 16),
                                _buildLocation(incident),
                                const SizedBox(height: 16),
                                _buildLiveStatusBadge(incident),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right Column
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildIncidentType(incident),
                                const SizedBox(height: 16),
                                _buildStatusHistory(incident),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Checklist
                      _buildChecklist(incident, currentStaff),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              }
            );
          }
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildHeader(IncidentModel incident) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5B71), // Match the pinkish-red exactly
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("OFFICIAL RESPONDER BRIEF", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("Room ${incident.roomNumber}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text("${incident.type.toUpperCase()} — Severity ${incident.severity}/5", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text("LIVE — ${incident.status.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummary(IncidentModel incident) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined, color: Color(0xFFFF5B71), size: 16),
              const SizedBox(width: 8),
              const Text("AI Situation Summary", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incident.translatedDescription ?? incident.description ?? "No description available.",
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentType(IncidentModel incident) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5B71), size: 16),
              const SizedBox(width: 8),
              const Text("Incident Type", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incident.type.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(IncidentModel incident) {
    return _buildCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFFFF5B71), size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Location", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Text("Room ${incident.roomNumber}\nFloor ${incident.floor}\nWing Unknown", 
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusBadge(IncidentModel incident) {
    return _buildCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5B71).withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFFF5B71).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5B71).withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10, 
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5B71), 
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0xFFFF5B71), blurRadius: 6)]
                  )
                ),
                const SizedBox(width: 12),
                Text("LIVE — ${incident.status.toUpperCase()}", 
                  style: const TextStyle(color: Color(0xFFFF5B71), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistory(IncidentModel incident) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFFFF5B71), size: 16),
                  const SizedBox(width: 8),
                  const Text("Status History", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const Text("See all", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          // Timeline pseudo-implementation based on the mock
          _buildTimelineStep("Staff Monitor", "${incident.assignedResponderName ?? 'staff'} 1 hour ago", "Safe", true, isFirst: true),
          const SizedBox(height: 20),
          _buildTimelineStep("Room/sight", "staff 2 hour ago", "available", false, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, String badgeText, bool isBadgeGreen, {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: isFirst ? Colors.greenAccent : const Color(0xFFFF5B71),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 35,
                color: Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isBadgeGreen ? Colors.greenAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isBadgeGreen ? Colors.greenAccent.withOpacity(0.3) : Colors.transparent),
            boxShadow: isBadgeGreen ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 10)] : null,
          ),
          child: Text(badgeText, style: TextStyle(color: isBadgeGreen ? Colors.greenAccent : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        )
      ],
    );
  }

  Widget _buildChecklist(IncidentModel incident, StaffModel? currentStaff) {
    return _buildCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("RESOLUTION CHECKLIST", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text("Managers must record to confirm the services notified before close the incident.", style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCheckItem("Guest Safe", _guestSafe, (v) => setState(() => _guestSafe = v!)),
              _buildCheckItem("Area Clear", _areaClear, (v) => setState(() => _areaClear = v!)),
              _buildCheckItem("Services Notified", _servicesNotified, (v) => setState(() => _servicesNotified = v!)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final firestore = Provider.of<FirestoreService>(context, listen: false);
                await firestore.updateIncident(incident.id, {'status': 'resolved'});
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A35),
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Close", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isChecked, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isChecked ? Colors.greenAccent.withOpacity(0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check, color: isChecked ? Colors.greenAccent : Colors.transparent, size: 24),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
