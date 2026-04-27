import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/nfc_service.dart';
import '../../../shared/widgets/glass_card.dart';

class NfcScanScreen extends StatefulWidget {
  const NfcScanScreen({super.key});

  @override
  _NfcScanScreenState createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen> {
  final NfcService _nfcService = NfcService();
  bool _success = false;
  String? _detectedRoom;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  Future<void> _startScanning() async {
    final result = await _nfcService.scanNfcTag();
    if (result != null && mounted) {
      setState(() {
        _success = true;
        _detectedRoom = result;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.go('/guest_home?room=$_detectedRoom');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.primary),
            child: _success ? _buildSuccessState() : _buildScanningState(),
          ),
          if (!_success)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Other ways to check in:", style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOption(context, '📷 Scan QR Code', '/qr_scan'),
                          const SizedBox(width: 12),
                          _buildOption(context, '✏️ Enter Room', '/manual_entry'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).scale(duration: 1500.ms).fadeOut(duration: 1500.ms),
              const Icon(Icons.contactless, size: 80, color: Colors.white),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            "Tap your phone to the",
            style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 16),
          ),
          Text(
            "bedside NFC tag",
            style: AppTextStyles.heading.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            "Look for the ResQ tag on your bedside table",
            style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      color: AppColors.success,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.white)
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              "$_detectedRoom Detected!",
              style: AppTextStyles.heading.copyWith(color: Colors.white),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text, String route) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(text, style: AppTextStyles.button.copyWith(color: AppColors.textPrimary, fontSize: 14)),
        ),
      ),
    );
  }
}
