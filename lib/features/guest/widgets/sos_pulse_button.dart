import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/theme_colors.dart';

class SosPulseButton extends StatefulWidget {
  final String roomNumber;
  const SosPulseButton({super.key, required this.roomNumber});

  @override
  _SosPulseButtonState createState() => _SosPulseButtonState();
}

class _SosPulseButtonState extends State<SosPulseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/sos_trigger?room=${widget.roomNumber}'),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRing(160, 0.4, 0.0),
              _buildRing(200, 0.25, 0.2),
              _buildRing(240, 0.1, 0.4),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 30,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      color: context.tc.isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRing(double size, double maxOpacity, double delay) {
    double progress = (_controller.value - delay);
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
          color: AppColors.primary.withOpacity(opacity.clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}
