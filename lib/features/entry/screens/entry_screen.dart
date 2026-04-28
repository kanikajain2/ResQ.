import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/theme_colors.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTopSection().animate().slideY(
                          begin: -0.5,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          children: [
                            _buildGuestCard(context)
                                .animate(delay: 100.ms)
                                .slideY(begin: 0.2, duration: 400.ms)
                                .fadeIn(),
                            const SizedBox(height: 12),
                            _buildStaffCard(context)
                                .animate(delay: 200.ms)
                                .slideY(begin: 0.2, duration: 400.ms)
                                .fadeIn(),
                            const SizedBox(height: 12),
                            _buildResponderCard(context)
                                .animate(delay: 300.ms)
                                .slideY(begin: 0.2, duration: 400.ms)
                                .fadeIn(),
                            const SizedBox(height: 32), // Replaced Spacer
                            _buildSubOptions(context)
                                .animate(delay: 400.ms)
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4D67), Color(0xFFFF8599)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF4D67).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: -10,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield, color: Colors.white, size: 32),
                  const SizedBox(width: 8),
                  Text('ResQ',
                      style:
                          AppTextStyles.heading.copyWith(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Always ready,\nanytime & anywhere!',
                style: AppTextStyles.display
                    .copyWith(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Your safety companion',
                style: AppTextStyles.body
                    .copyWith(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedScale(
          scale: isHovered ? 1.05 : 1.0,
          duration: 200.ms,
          child: GestureDetector(
            onTap: () => context.push('/nfc_scan'),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 12))
                      ]
                    : [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6))
                      ],
                border: Border.all(
                  color: isHovered 
                    ? AppColors.primary.withValues(alpha: 0.3) 
                    : Colors.transparent,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 25),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Hotel Guest",
                            style: AppTextStyles.title.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text("Check-in & SOS access",
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedScale(
          scale: isHovered ? 1.05 : 1.0,
          duration: 200.ms,
          child: GestureDetector(
            onTap: () => context.push('/staff_login'),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4D67), Color(0xFFFF8599)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: const Color(0xFFFF4D67).withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15))
                      ]
                    : [
                        BoxShadow(
                            color: const Color(0xFFFF4D67).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 25),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Command Staff",
                            style: AppTextStyles.title.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text("Dashboard & Monitoring",
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponderCard(BuildContext context) {
    bool isHovered = true;
    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedScale(
          scale: isHovered ? 1.05 : 1.0,
          duration: 200.ms,
          child: GestureDetector(
            onTap: () {
              // For demo, show a dialog to enter incident ID
              showDialog(
                context: context,
                builder: (ctx) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    title: const Text("Enter Incident ID"),
                    content: TextField(
                      controller: controller,
                      decoration:
                          const InputDecoration(hintText: "Incident ID"),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel")),
                      TextButton(
                        onPressed: () {
                          final id = controller.text.trim();
                          if (id.isNotEmpty) {
                            Navigator.pop(ctx);
                            context.push('/responder_portal/$id');
                          }
                        },
                        child: const Text("View Brief"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A28),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ]
                    : [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.emergency_share_rounded,
                        color: AppColors.primary, size: 25),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("First Responder",
                            style: AppTextStyles.title.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text("Live Incident Briefs",
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubOptions(BuildContext context) {
    return Column(
      children: [
        Text("Other ways to check in:",
            style: AppTextStyles.caption
                .copyWith(color: context.tc.textSecondary)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPillOption(context, '📱 NFC', '/nfc_scan'),
            const SizedBox(width: 8),
            _buildPillOption(context, '📷 QR Scan', '/qr_scan'),
            const SizedBox(width: 8),
            _buildPillOption(context, '✏️ Manual', '/manual_entry'),
          ],
        ),
      ],
    );
  }

  Widget _buildPillOption(BuildContext context, String text, String route) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedScale(
          scale: isHovered ? 1.1 : 1.0,
          duration: 200.ms,
          child: InkWell(
            onTap: () => context.push(route),
            borderRadius: BorderRadius.circular(100),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(100),
                color: isHovered
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : context.tc.cardColor,
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8)
                      ]
                    : [],
              ),
              child: Text(
                text,
                style: AppTextStyles.button
                    .copyWith(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
