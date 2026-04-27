import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shield Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.shield,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ).animate()
          .scale(duration: 300.ms, begin: const Offset(0,0), curve: Curves.easeOutBack),
          
        const SizedBox(height: 16),
        
        // ResQ Text
        Text(
          'ResQ',
          style: AppTextStyles.display.copyWith(color: Colors.white),
        ).animate(delay: 600.ms)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.5, end: 0.0),
          
        const SizedBox(height: 8),
        
        // Tagline
        Text(
          'Emergency help, always within reach',
          style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.8)),
        ).animate(delay: 900.ms)
          .fadeIn(duration: 300.ms),
          
        const SizedBox(height: 32),
        
        // Loading Dots
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ).animate(
              delay: (1500 + index * 200).ms,
              onPlay: (controller) => controller.repeat(),
            ).scaleXY(begin: 0.5, end: 1.5, duration: 400.ms, curve: Curves.easeInOut)
             .then().scaleXY(begin: 1.5, end: 0.5, duration: 400.ms, curve: Curves.easeInOut);
          }),
        ),
      ],
    );
  }
}
