import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/theme_colors.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/assignment_service.dart';
import '../../../core/models/incident_model.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/nearby_service.dart';
import '../../staff/widgets/connectivity_banner.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SosTriggerScreen extends StatefulWidget {
  final String? initialType;
  final String roomNumber;
  const SosTriggerScreen({super.key, this.initialType, required this.roomNumber});

  @override
  _SosTriggerScreenState createState() => _SosTriggerScreenState();
}

class _SosTriggerScreenState extends State<SosTriggerScreen>
    with SingleTickerProviderStateMixin {
  String _selectedType = 'other';
  final TextEditingController _descController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  final List<Map<String, dynamic>> _incidentTypes = [
    {'id': 'fire', 'label': 'Fire', 'icon': '🔥'},
    {'id': 'medical', 'label': 'Medical', 'icon': '🏥'},
    {'id': 'security', 'label': 'Security', 'icon': '🔒'},
    {'id': 'harassment', 'label': 'Harassment', 'icon': '⚠️'},
    {'id': 'theft', 'label': 'Theft', 'icon': '👜'},
    {'id': 'other', 'label': 'Other', 'icon': '❓'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    _speechService.init();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _descController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMic() {
    if (_isListening) {
      _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speechService.startListening((text) {
        if (mounted) {
          setState(() {
            _descController.text = text;
            _isListening = false;
          });
        }
      });
    }
  }

  void _onSend() async {
    final description = _descController.text.isEmpty
        ? "Emergency alert from room ${widget.roomNumber}"
        : _descController.text;

    setState(() => _isLoading = true);

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final gemini = Provider.of<GeminiService>(context, listen: false);

      final triageStartedAt = DateTime.now();
      final triage = await gemini.triageIncident(_selectedType, description);
      final triageCompletedAt = DateTime.now();

      final incidentId = const Uuid().v4();
      final assignment = AssignmentService();
      
      // Find closest staff (mock coordinates for demo)
      final closestId = await assignment.findClosestStaff(_selectedType, 28.6139, 77.2090);

      final incident = IncidentModel(
        id: incidentId,
        type: _selectedType,
        description: description,
        roomNumber: widget.roomNumber,
        guestId: 'guest_123',
        authMethod: 'manual',
        severity: (triage['severity'] ?? 3).toInt(),
        suggestedTeam: triage['suggestedTeam'] ?? 'security',
        aiSummary: triage['summary'] ?? description,
        status: 'received',
        closestStaffId: closestId,
        createdAt: DateTime.now(),
        triageStartedAt: triageStartedAt,
        triageCompletedAt: triageCompletedAt,
      );

      final actualId = await firestore.createIncident(incident).timeout(
        const Duration(seconds: 5),
        onTimeout: () async {
          // If Firestore fails/times out, we are likely offline
          final nearby = Provider.of<NearbyService>(context, listen: false);
          if (nearby.hasConnections) {
            await nearby.broadcastSOS(incident.toMeshMap());
            return incidentId; // Use the local ID
          }
          throw TimeoutException("Database connection timed out and no mesh peers found.");
        },
      );

      // Also broadcast via mesh if we have connections (for relaying)
      final nearby = Provider.of<NearbyService>(context, listen: false);
      if (nearby.hasConnections) {
        await nearby.broadcastSOS(incident.toMeshMap());
      }

      if (mounted) {
        context.go('/status_tracking?type=$_selectedType&id=$actualId&room=${widget.roomNumber}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is TimeoutException 
              ? e.message! 
              : "Error sending alert: $e. Make sure Firestore is enabled in your Firebase Console."),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tc.bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Send Emergency Alert",
                style: AppTextStyles.title
                    .copyWith(color: context.tc.textPrimary)),
            Text("We'll notify help immediately",
                style: AppTextStyles.caption
                    .copyWith(color: context.tc.textSecondary)),
          ],
        ),
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConnectivityBanner(isOnline: Provider.of<ConnectivityService>(context).isOnline),
                  Text("What's the emergency?",
                      style: AppTextStyles.title
                          .copyWith(color: context.tc.textPrimary)),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _incidentTypes.length,
                    itemBuilder: (context, index) {
                      final type = _incidentTypes[index];
                      final isSelected = _selectedType == type['id'];
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedType = type['id'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppGradients.primary : null,
                              color: isSelected ? null : context.tc.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : context.tc.border,
                                width: 2,
                              ),
                              boxShadow: isSelected ? context.tc.cardShadow : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(type['icon'] as String,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  type['label'] as String,
                                  style: AppTextStyles.body.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : context.tc.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text("Describe the situation",
                      style: AppTextStyles.title
                          .copyWith(color: context.tc.textPrimary)),
                  const SizedBox(height: 12),
                  // Mic button with pulse animation
                  Center(
                    child: GestureDetector(
                      onTap: _toggleMic,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isListening ? 90 : 80,
                          height: _isListening ? 90 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isListening ? null : AppGradients.primary,
                            color: _isListening
                                ? const Color.fromARGB(255, 252, 99, 112)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? const Color.fromARGB(255, 255, 101, 114)
                                        : AppColors.primary)
                                    .withValues(alpha: 0.4),
                                blurRadius: _isListening ? 24 : 12,
                                spreadRadius: _isListening ? 4 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: context.tc.isDark ? Colors.black : Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isListening) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Listening… speak now',
                        style: AppTextStyles.caption.copyWith(
                            color: const Color.fromARGB(255, 234, 95, 107)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  MouseRegion(
                    cursor: SystemMouseCursors.text,
                    child: TextField(
                      controller: _descController,
                      style: TextStyle(color: context.tc.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Or type details here...",
                        hintStyle: TextStyle(color: context.tc.textSecondary),
                        filled: true,
                        fillColor: context.tc.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Crisis-aware Send Button
                  AnimatedContainer(
                    duration: 300.ms,
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isLoading ? [
                        BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)
                      ] : [],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.red : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _onSend,
                      child: _isLoading 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              ),
                              const SizedBox(width: 16),
                              Text("DISPATCHING HELP...", style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            ],
                          )
                        : Text("SEND EMERGENCY ALERT", style: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Dispatching Overlay
          if (_isLoading)
            Container(
              color: Colors.red.withValues(alpha: 0.1),
            ).animate(onPlay: (c) => c.repeat()).shimmer(color: Colors.redAccent.withValues(alpha: 0.2), duration: 1.seconds),
        ],
      ),
    );
  }
}
