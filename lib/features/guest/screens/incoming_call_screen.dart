import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_shadows.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with TickerProviderStateMixin {
  bool _isConnected = false;
  int _countdown = 3;
  Timer? _timer;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        setState(() => _isConnected = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: _isConnected 
            ? const LinearGradient(colors: [AppColors.primaryDark, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter)
            : AppGradients.primary,
        ),
        child: SafeArea(
          child: _isConnected ? _buildActiveCall() : _buildRinging(),
        ),
      ),
    );
  }

  Widget _buildRinging() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildAnimatedRing(200, 0.4, 0.0),
              _buildAnimatedRing(250, 0.25, 0.25),
              _buildAnimatedRing(300, 0.1, 0.5),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [AppShadows.card]),
                child: const Icon(Icons.phone_in_talk, color: AppColors.primary, size: 48)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shake(duration: 500.ms, hz: 4),
              ),
            ],
          ),
        ),
        Text("Hotel Security", style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 8),
        Text("is calling to verify your alert", style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
          child: Text("Auto-answering in $_countdown seconds...", style: AppTextStyles.button.copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildActiveCall() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text("Hotel Security", style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text("00:14", style: AppTextStyles.display.copyWith(color: Colors.white, fontWeight: FontWeight.w400)),
              const SizedBox(height: 8),
              Text("Room 304 - Fire Alert", style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
        
        // Waveform placeholder
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

        Padding(
          padding: const EdgeInsets.only(bottom: 64.0),
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
        ),
      ],
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
