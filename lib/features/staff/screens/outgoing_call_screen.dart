import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';

class OutgoingCallScreen extends StatefulWidget {
  const OutgoingCallScreen({super.key});

  @override
  _OutgoingCallScreenState createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> with TickerProviderStateMixin {
  bool _isConnected = false;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    
    // Simulate connection after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isConnected = true);
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _isConnected 
            ? const LinearGradient(colors: [AppColors.primaryDark, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter)
            : AppGradients.primary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Text("🔥", style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Room 304", style: AppTextStyles.title.copyWith(color: AppColors.textPrimary)),
                            Text("Smoke detected in bathroom", style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _isConnected ? _buildActiveCall() : _buildConnecting(),
              ),
              _buildVerdictButtons(),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnecting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            _buildAnimatedRing(200, 0.4, 0.0),
            _buildAnimatedRing(250, 0.25, 0.25),
            _buildAnimatedRing(300, 0.1, 0.5),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.phone_in_talk, color: AppColors.primary, size: 48),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Text("Connecting to Room 304", style: AppTextStyles.heading.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) => const Padding(
            padding: EdgeInsets.all(4.0),
            child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
          ).animate(onPlay: (c) => c.repeat()).fade(duration: 500.ms, delay: (index * 200).ms)),
        ),
      ],
    );
  }

  Widget _buildActiveCall() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(100)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text("Connected", style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text("00:45", style: AppTextStyles.display.copyWith(color: Colors.white, fontWeight: FontWeight.w400)),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 40,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            ).animate(onPlay: (controller) => controller.repeat())
             .scaleY(begin: 0.5, end: 1.5, duration: (300 + index * 100).ms, curve: Curves.easeInOut)
             .then().scaleY(begin: 1.5, end: 0.5, duration: (300 + index * 100).ms, curve: Curves.easeInOut);
          }),
        ),
      ],
    );
  }

  Widget _buildVerdictButtons() {
    if (!_isConnected) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                context.pop(); // Real
              },
              child: const Text("✓ Real Emergency", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                context.pop(); // False alarm
              },
              child: const Text("✗ False Alarm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, curve: Curves.easeOut);
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCallButton(Icons.mic_off, Colors.white.withOpacity(0.2), Colors.white, () {}),
          const SizedBox(width: 24),
          _buildCallButton(Icons.call_end, AppColors.danger, Colors.white, () {
            context.pop();
          }, size: 72),
          const SizedBox(width: 24),
          _buildCallButton(Icons.volume_up, Colors.white.withOpacity(0.2), Colors.white, () {}),
        ],
      ),
    );
  }

  Widget _buildCallButton(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap, {double size = 56}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }

  Widget _buildAnimatedRing(double size, double maxOpacity, double delay) {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (context, child) {
        double progress = (_ringController.value - delay);
        if (progress < 0) progress += 1.0;
        double scale = 0.5 + (0.5 * progress);
        double opacity = maxOpacity * (1.0 - progress);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
            ),
          ),
        );
      },
    );
  }
}
