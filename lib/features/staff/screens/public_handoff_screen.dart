import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/incident_model.dart';

class PublicHandoffScreen extends StatefulWidget {
  final String incidentId;
  const PublicHandoffScreen({super.key, required this.incidentId});

  @override
  State<PublicHandoffScreen> createState() => _PublicHandoffScreenState();
}

class _PublicHandoffScreenState extends State<PublicHandoffScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateExpiry();
    });
  }

  void _calculateExpiry() {
    // Note: We need the incident data to calculate this accurately.
    // For now, this is triggered by the StreamBuilder but managed here.
  }

  void _updateRemainingTime(DateTime createdAt) {
    final expiryTime = createdAt.add(const Duration(hours: 6));
    final now = DateTime.now();
    final diff = expiryTime.difference(now);

    if (diff.isNegative) {
      if (!_isExpired) {
        setState(() {
          _isExpired = true;
          _remainingTime = Duration.zero;
        });
      }
    } else {
      setState(() {
        _isExpired = false;
        _remainingTime = diff;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Color _getTimerColor() {
    if (_remainingTime.inHours >= 2) return Colors.green;
    if (_remainingTime.inHours >= 1) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: StreamBuilder<IncidentModel>(
        stream: firestore.streamIncident(widget.incidentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final incident = snapshot.data!;
          
          // Update timer logic based on stream data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRemainingTime(incident.createdAt);
          });

          return Column(
            children: [
              _buildHeader(incident),
              if (_isExpired)
                Container(
                  width: double.infinity,
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text("THIS BRIEF HAS EXPIRED", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard("AI Triage Summary", incident.aiSummary ?? incident.description, Icons.psychology),
                      const SizedBox(height: 16),
                      _buildInfoCard("Room Information", "Room ${incident.roomNumber}", Icons.meeting_room),
                      const SizedBox(height: 16),
                      _buildInfoCard("Incident Type", incident.type.toUpperCase(), Icons.warning_amber_rounded),
                      const SizedBox(height: 16),
                      _buildResponderSection(incident),
                      const SizedBox(height: 24),
                      Text("RESPONSE TIMELINE", 
                        style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.5), letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      _buildTimeline(incident),
                      const SizedBox(height: 24),
                      Text("LIVE STATUS: ${incident.status.toUpperCase()}", 
                        style: AppTextStyles.title.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(IncidentModel incident) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("OFFICIAL RESPONDER VIEW", style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8), letterSpacing: 2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTimerColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _getTimerColor().withOpacity(0.5)),
                ),
                child: Text(
                  _isExpired ? "EXPIRED" : "Expires in ${_formatDuration(_remainingTime)}",
                  style: TextStyle(color: _getTimerColor(), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Room ${incident.roomNumber}", style: AppTextStyles.heading.copyWith(color: Colors.white, fontSize: 36)),
          Text("Incident ID: ${widget.incidentId.substring(0, 8)}", style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildResponderSection(IncidentModel incident) {
    final responderName = incident.assignedResponderName ?? "Unassigned";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Assigned Responder", style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 4),
                Text(responderName, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (incident.assignedResponderName != null && incident.assignedResponderName!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _isExpired ? null : () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Contact Responder"),
                    content: Text("Contact $responderName via the hotel front desk."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.phone, size: 16),
              label: const Text("Call Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(IncidentModel incident) {
    final dateFormat = DateFormat('HH:mm dd MMM');
    
    final events = [
      {'label': 'Alert received', 'time': incident.createdAt},
      if (incident.verifiedAt != null) {'label': 'Alert verified by staff', 'time': incident.verifiedAt},
      if (incident.assignedResponderName != null && incident.assignedResponderName!.isNotEmpty) 
        {'label': 'Responder assigned', 'time': incident.updatedAt ?? incident.createdAt},
      if (incident.resolvedAt != null) {'label': 'Incident resolved', 'time': incident.resolvedAt},
    ];

    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(color: Color(0xFFFF7F66), shape: BoxShape.circle),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: Colors.white.withOpacity(0.1)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(event['time'] as DateTime), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 4),
                Text(content, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Text(_isExpired ? "EXPIRED" : "VIEW EXPIRES IN ${_formatDuration(_remainingTime)}", 
        style: AppTextStyles.caption.copyWith(color: _isExpired ? Colors.red : Colors.white.withOpacity(0.3))),
    );
  }
}
