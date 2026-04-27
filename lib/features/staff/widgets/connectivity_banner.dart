 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/nearby_service.dart';
import '../../../core/providers/connectivity_provider.dart';

class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;

  const ConnectivityBanner({super.key, this.isOnline = true});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    final isOnline = connectivity.isOnline;
    
    return Consumer<NearbyService>(
      builder: (context, nearby, _) {
        final count = nearby.connectedEndpoints.length;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: double.infinity,
          height: isOnline ? 0 : 44,
          margin: EdgeInsets.only(bottom: isOnline ? 0 : 8),
          decoration: BoxDecoration(
            gradient: isOnline 
              ? null 
              : LinearGradient(
                  colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            boxShadow: isOnline ? [] : [
              BoxShadow(color: AppColors.warning.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: isOnline ? const SizedBox.shrink() : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hub_rounded, color: Colors.white, size: 18)
                .animate(onPlay: (controller) => controller.repeat())
                .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1))
                .then()
                .scale(duration: 1.seconds, begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9)),
              const SizedBox(width: 12),
              Text(
                "OFFLINE MESH ACTIVE",
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 11
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  "$count NODES",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
