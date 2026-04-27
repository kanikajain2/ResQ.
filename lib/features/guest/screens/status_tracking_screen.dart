import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/theme_colors.dart';
import '../widgets/retraction_bar.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/translate_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/assignment_service.dart';
import '../../../core/models/incident_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/staff_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../staff/widgets/connectivity_banner.dart';
import '../../../core/services/connectivity_service.dart';

class StatusTrackingScreen extends StatefulWidget {
  final String incidentType;
  final String? incidentId;
  final String roomNumber;
  const StatusTrackingScreen(
      {super.key,
      this.incidentType = 'other',
      this.incidentId,
      required this.roomNumber});

  @override
  _StatusTrackingScreenState createState() => _StatusTrackingScreenState();
}

class _StatusTrackingScreenState extends State<StatusTrackingScreen> {
  bool _isCancelled = false;
  bool _isResolved = false;
  bool _isUpdating = false;
  final TextEditingController _messageController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  String _status = 'pending';
  final TranslateService _translateService = TranslateService();
  bool _initialLoadDone = false;

  static const _typeEmoji = {
    'fire': '🔥',
    'medical': '🏥',
    'security': '🔒',
    'harassment': '⚠️',
    'theft': '👜',
    'other': '🆘',
  };

  static const _typeLabel = {
    'fire': 'Fire',
    'medical': 'Medical',
    'security': 'Security',
    'harassment': 'Harassment',
    'theft': 'Theft',
    'other': 'Emergency',
  };

  @override
  void initState() {
    super.initState();
    _speechService.init();
    if (widget.incidentId == null) {
      // Logically this shouldn't happen now, but as a safety:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Incident context lost.")),
        );
        context.go('/guest_home?room=${widget.roomNumber}');
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _emoji => _typeEmoji[widget.incidentType] ?? '🆘';
  String get _label => _typeLabel[widget.incidentType] ?? 'Emergency';

  @override
  Widget build(BuildContext context) {
    // Resolved screen
    if (_isResolved) {
      return Scaffold(
        backgroundColor: context.tc.bgColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded,
                color: AppColors.success, size: 80),
            const SizedBox(height: 24),
            Text("Alert Resolved",
                style: AppTextStyles.heading
                    .copyWith(color: context.tc.textPrimary)),
            const SizedBox(height: 12),
            Text(
              "Your safety is our priority. Please help us improve by providing feedback.",
              style:
                  AppTextStyles.body.copyWith(color: context.tc.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Star Rating (Mock)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (index) => IconButton(
                        icon: const Icon(Icons.star_border,
                            size: 32, color: Colors.amber),
                        onPressed: () {},
                      )),
            ),
            const SizedBox(height: 16),

            TextField(
              maxLines: 3,
              style: TextStyle(color: context.tc.textPrimary),
              decoration: InputDecoration(
                hintText: "How was the response? (Optional)",
                hintStyle: TextStyle(color: context.tc.textSecondary),
                filled: true,
                fillColor: context.tc.inputBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () =>
                    context.go('/guest_home?room=${widget.roomNumber}'),
                child: const Text("Submit & Finish",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.go('/guest_home?room=${widget.roomNumber}'),
              child: Text("Skip",
                  style: TextStyle(color: context.tc.textSecondary)),
            )
          ],
        ),
      );
    }

    // Cancelled screen
    if (_isCancelled) {
      return Scaffold(
        backgroundColor: context.tc.bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: Color.fromARGB(255, 74, 252, 163), size: 80),
              const SizedBox(height: 16),
              Text("Alert Cancelled",
                  style: AppTextStyles.heading
                      .copyWith(color: context.tc.textPrimary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    context.go('/guest_home?room=${widget.roomNumber}'),
                child: const Text("Return Home"),
              )
            ],
          ),
        ),
      );
    }

    return StreamBuilder<IncidentModel>(
      stream: widget.incidentId != null
          ? Provider.of<FirestoreService>(context, listen: false)
              .streamIncident(widget.incidentId!)
          : Stream.empty(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !_initialLoadDone) {
          return _buildOptimisticUI();
        }

        if (snapshot.hasData) {
          _initialLoadDone = true;
          final incident = snapshot.data!;
          _status = incident.status;
          if (_status == 'resolved' && !_isResolved) {
            Future.microtask(() => setState(() => _isResolved = true));
          }

          return Scaffold(
            backgroundColor: context.tc.bgColor,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.tc.textPrimary),
                onPressed: () =>
                    context.go('/guest_home?room=${widget.roomNumber}'),
              ),
              title: Text("Your Alert",
                  style: AppTextStyles.title
                      .copyWith(color: context.tc.textPrimary)),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "$_emoji $_label",
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            body: Column(
              children: [
                ConnectivityBanner(
                    isOnline:
                        Provider.of<ConnectivityService>(context).isOnline),
                _buildHeroCard(incident),
                RetractionBar(
                  onCancel: () async {
                    if (widget.incidentId == null) return;

                    // Show reason picker
                    final reason = await showModalBottomSheet<String>(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(28))),
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("Why are you cancelling?",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          ...[
                            'Tapped by mistake',
                            'Situation resolved itself',
                            'Was testing the app',
                            'Wrong button',
                          ].map((r) => ListTile(
                                title: Text(r),
                                onTap: () => Navigator.pop(ctx, r),
                              )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );

                    if (reason != null && widget.incidentId != null) {
                      final firestore =
                          Provider.of<FirestoreService>(context, listen: false);
                      await firestore.updateIncident(widget.incidentId!, {
                        'isFalseAlarm': true,
                        'falseAlarmReason': reason,
                        'status': 'resolved',
                      });
                      if (mounted) setState(() => _isCancelled = true);
                    }
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline,
                              color: Colors.black),
                      label: Text(
                          _isUpdating
                              ? "Updating..."
                              : "Help has arrived — Dismiss alert",
                          style: const TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isUpdating
                          ? null
                          : () async {
                              setState(() => _isUpdating = true);
                              try {
                                if (widget.incidentId != null) {
                                  await Provider.of<FirestoreService>(context,
                                          listen: false)
                                      .updateIncident(widget.incidentId!,
                                          {'status': 'resolved'});
                                }
                                if (mounted) setState(() => _isResolved = true);
                              } catch (e) {
                                if (e.toString().contains('not-found')) {
                                  if (mounted)
                                    setState(() => _isResolved = true);
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text("Error dismissing alert: $e"),
                                        backgroundColor: AppColors.danger),
                                  );
                                }
                              } finally {
                                if (mounted)
                                  setState(() => _isUpdating = false);
                              }
                            },
                    ),
                  ),
                ),
                Expanded(child: _buildChatSection(incident)),
                _buildInputRow(),
              ],
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildHeroCard(IncidentModel incident) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFF4D67), const Color(0xFFFF8599)],
        ),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Help is on the way",
                        style: AppTextStyles.heading.copyWith(
                            color: Colors.black, fontWeight: FontWeight.w900)),
                    if (incident.assignedResponderName?.isNotEmpty == true)
                      StreamBuilder<StaffModel?>(
                        stream: Provider.of<FirestoreService>(context,
                                listen: false)
                            .streamStaffMember(incident.assignedResponderId!),
                        builder: (context, staffSnap) {
                          final staff = staffSnap.data;
                          final role = staff?.role ?? "Responder";
                          return Text(
                            "Assigned: ${incident.assignedResponderName} ($role)",
                            style: AppTextStyles.body.copyWith(
                                color: Colors.black.withValues(alpha: 0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (incident.assignedResponderId?.isNotEmpty == true)
                StreamBuilder<StaffModel?>(
                    stream:
                        Provider.of<FirestoreService>(context, listen: false)
                            .streamStaffMember(incident.assignedResponderId!),
                    builder: (context, staffSnap) {
                      final staff = staffSnap.data;
                      if (staff?.phone?.isNotEmpty == true) {
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.black,
                              child: IconButton(
                                icon: const Icon(Icons.phone,
                                    color: AppColors.primary),
                                onPressed: () =>
                                    launchUrl(Uri.parse('tel:${staff!.phone}')),
                              ),
                            ).animate().scale(),
                            const SizedBox(height: 4),
                            Text("CALL",
                                style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0)),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
            ],
          ),
          const SizedBox(height: 12),
          _buildStepper(incident.status),
        ],
      ),
    );
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'received':
        return 0;
      case 'assigned':
        return 1;
      case 'enRoute':
        return 2;
      case 'onScene':
        return 3;
      case 'resolved':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildStepper(String status) {
    final steps = [
      {'label': 'Received', 'icon': Icons.access_time},
      {'label': 'Assigned', 'icon': Icons.person},
      {'label': 'En Route', 'icon': Icons.directions_car},
      {'label': 'On Scene', 'icon': Icons.location_on},
    ];
    final current = _getStepIndex(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          // Step Icon + Label
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: i < current
                      ? const Color(0xFF2ED573)
                      : i == current
                          ? AppColors.primary
                          : Colors.grey.shade300,
                  child: Icon(
                    i < current ? Icons.check : steps[i]['icon'] as IconData,
                    color: i <= current ? Colors.black : Colors.black.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ).animate(onPlay: (c) => i == current ? c.repeat(reverse: true) : null),
                const SizedBox(height: 4),
                Text(
                  steps[i]['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: i > current
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.black,
                    fontWeight: i == current ? FontWeight.w900 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          // Connecting Line
          if (i < steps.length - 1)
            Container(
              width: 20,
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              color: i < current
                  ? Colors.black
                  : Colors.black.withValues(alpha: 0.2),
            ),
        ],
      ],
    );
  }

  Widget _buildChatSection(IncidentModel incident) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _buildSafetyInstructions(incident.assemblyPoint),
        const SizedBox(height: 16),
        if (widget.incidentId != null)
          StreamBuilder<List<MessageModel>>(
            stream: Provider.of<FirestoreService>(context, listen: false)
                .streamMessages(widget.incidentId!),
            builder: (context, snapshot) {
              final msgs = snapshot.data ?? [];
              if (msgs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("No messages yet",
                      style: AppTextStyles.caption
                          .copyWith(color: context.tc.textSecondary)),
                );
              }
              return Column(
                children: msgs.map((msg) {
                  if (msg.senderRole == 'staff') {
                    return _buildStaffMessage(msg);
                  } else {
                    return _buildGuestMessage(msg);
                  }
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSafetyInstructions(String? assemblyPoint) {
    return Column(
      children: [
        if (assemblyPoint != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [AppShadows.card],
            ),
            child: Row(
              children: [
                const Icon(Icons.meeting_room_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("EMERGENCY ASSEMBLY POINT",
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2)),
                      Text(assemblyPoint,
                          style: AppTextStyles.title.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      const Text("Please proceed here if safe to do so.",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().shimmer(duration: 2.seconds).slideY(begin: 0.1),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.tc.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("While you wait:",
                  style: AppTextStyles.title
                      .copyWith(color: context.tc.textPrimary)),
              const SizedBox(height: 8),
              _buildBullet("Stay calm and remain in your room"),
              _buildBullet("Do not use the elevator"),
              _buildBullet("Follow staff instructions when they arrive"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ",
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(text,
                  style: AppTextStyles.body
                      .copyWith(color: context.tc.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildStaffMessage(MessageModel msg) {
    final showTranslation =
        msg.translatedText != null && msg.translatedText != msg.text;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.tc.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTranslation) ...[
              Text("Original: ${msg.text}",
                  style: AppTextStyles.caption.copyWith(
                      color: context.tc.textSecondary,
                      fontStyle: FontStyle.italic)),
              const Divider(height: 8),
              Text(msg.translatedText!,
                  style: AppTextStyles.body.copyWith(
                      color: context.tc.textPrimary,
                      fontWeight: FontWeight.bold)),
            ] else
              SelectableText(msg.text,
                  style: AppTextStyles.body
                      .copyWith(color: context.tc.textPrimary)),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.2);
  }

  Widget _buildGuestMessage(MessageModel msg) {
    final showTranslation =
        msg.translatedText != null && msg.translatedText != msg.text;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showTranslation) ...[
              Text("Original: ${msg.text}",
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white70, fontStyle: FontStyle.italic)),
              const Divider(height: 8, color: Colors.white24),
              Text(msg.translatedText!,
                  style: AppTextStyles.body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ] else
              SelectableText(msg.text,
                  style: AppTextStyles.body.copyWith(color: Colors.white)),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.incidentId == null) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    // Translate guest message
    final translated = await _translateService.translateToEnglish(text);

    // Save guest message to Firestore
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    await firestore.addMessage(
      widget.incidentId!,
      MessageModel(
        id: '',
        senderId: 'guest',
        senderRole: 'guest',
        text: text,
        translatedText: translated,
        createdAt: DateTime.now(),
      ),
    );

    // Get Gemini reply and save as staff message
    final aiReply = await _geminiService.generateChatReply(text,
        incidentType: widget.incidentType);

    await firestore.addMessage(
      widget.incidentId!,
      MessageModel(
        id: '',
        senderId: 'ai_staff',
        senderRole: 'staff',
        text: aiReply,
        translatedText: aiReply,
        createdAt: DateTime.now(),
      ),
    );

    // Auto-scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speechService.startListening((text) {
        if (mounted) {
          setState(() {
            _messageController.text = text;
            _isListening = false;
          });
        }
      });
    }
  }

  Widget _buildInputRow() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.tc.cardColor,
        border: Border(
            top: BorderSide(color: context.tc.border.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.danger.withValues(alpha: 0.15)
                      : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? AppColors.danger : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: context.tc.textPrimary),
                decoration: InputDecoration(
                  hintText: _isListening ? "Listening..." : "Type a message...",
                  hintStyle: TextStyle(color: context.tc.textSecondary),
                  filled: true,
                  fillColor: context.tc.inputBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    gradient: AppGradients.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimisticUI() {
    return Scaffold(
      backgroundColor: context.tc.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.tc.textPrimary),
          onPressed: () => context.go('/guest_home?room=${widget.roomNumber}'),
        ),
        title: Text("Your Alert",
            style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppGradients.card,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28)),
              boxShadow: [AppShadows.card],
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Alert received",
                        style: AppTextStyles.heading
                            .copyWith(color: Colors.black)),
                    const SizedBox(width: 12),
                    _buildPulseDot(),
                  ],
                ),
                Text("Connecting to team...",
                    style: AppTextStyles.body
                        .copyWith(color: Colors.black.withOpacity(0.7))),
                const SizedBox(height: 12),
                _buildStepper('received'),
              ],
            ),
          ),
          const Spacer(),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text("Syncing live status...",
              style: AppTextStyles.caption
                  .copyWith(color: context.tc.textSecondary)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPulseDot() {
    return Container(
      width: 10,
      height: 10,
      decoration:
          const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.5, 1.5),
            duration: 800.ms,
            curve: Curves.easeInOut)
        .fadeOut(begin: 1.0, duration: 800.ms);
  }
}
