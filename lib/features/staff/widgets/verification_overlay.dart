import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';

class VerificationOverlay extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const VerificationOverlay({super.key, required this.onConfirm, required this.onCancel});

  @override
  _VerificationOverlayState createState() => _VerificationOverlayState();
}

class _VerificationOverlayState extends State<VerificationOverlay> {
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && mounted) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        // Auto confirm when depleted
        widget.onConfirm();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(gradient: AppGradients.primary),
                child: Column(
                  children: [
                    Text("🚨 Unverified Alert", style: AppTextStyles.heading.copyWith(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text("Room 304 • Fire Alert", style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("You are closest to this room", style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text("🔥", style: TextStyle(fontSize: 40))),
                    ).animate(onPlay: (controller) => controller.repeat()).scale(duration: 1.seconds, curve: Curves.easeInOut).then().scale(begin: const Offset(1.1, 1.1), end: const Offset(1/1.1, 1/1.1), duration: 1.seconds, curve: Curves.easeInOut),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Text("AI Summary", style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Smoke detected in bathroom. Guest reports trouble breathing.", style: AppTextStyles.body),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Time since alert:", style: AppTextStyles.caption),
                              Text("0m 45s", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.danger)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: widget.onConfirm,
                        child: Text("✓ CONFIRMED — Real Emergency", style: AppTextStyles.button),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: widget.onCancel,
                        child: Text("✗ False Alarm — Cancel", style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => context.push('/outgoing_call'),
                      icon: const Icon(Icons.phone, color: AppColors.textPrimary),
                      label: Text("Call Guest", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: _secondsRemaining / 60,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
                minHeight: 4,
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: -1.0, duration: 400.ms, curve: Curves.easeOutCubic),
    );
  }
}
