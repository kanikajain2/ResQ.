import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';

class FloatingSosButton extends StatefulWidget {
  const FloatingSosButton({super.key});

  @override
  _FloatingSosButtonState createState() => _FloatingSosButtonState();
}

class _FloatingSosButtonState extends State<FloatingSosButton> with SingleTickerProviderStateMixin {
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
    return Positioned(
      bottom: 24,
      right: 24,
      child: GestureDetector(
        onTap: () {
          context.push('/countdown');
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildRing(80, 0.4, 0.0),
                _buildRing(100, 0.25, 0.2),
                _buildRing(120, 0.1, 0.4),
                Container(
                  width: 64,
                  height: 64,
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
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
