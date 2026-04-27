import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  String? _detectedRoom;
  bool _isNavigating = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isNavigating) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _detectedRoom = barcode.rawValue;
          _isNavigating = true;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.go('/guest_home?room=$_detectedRoom');
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          "Point at your room QR code",
                          style: AppTextStyles.title.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      height: 2,
                      color: AppColors.primary,
                    ), // Simplistic animated scan line placeholder
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _detectedRoom != null ? "Detected: $_detectedRoom" : "Scanning...",
                          style: AppTextStyles.title.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/manual_entry'),
                          child: Text("Having trouble? Enter manually", style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
