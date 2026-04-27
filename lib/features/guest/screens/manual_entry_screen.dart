import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/theme_colors.dart';
import '../../../shared/widgets/gradient_button.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> with SingleTickerProviderStateMixin {
  final _roomController = TextEditingController();
  final _floorController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _roomController.dispose();
    _floorController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tc.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: context.tc.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 32),
                Text("Enter Your Room Details", style: AppTextStyles.heading.copyWith(color: context.tc.textPrimary)),
                const SizedBox(height: 8),
                Text("Find your room number on your key card", style: AppTextStyles.body.copyWith(color: context.tc.textSecondary)),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _roomController,
                  hint: "Room Number (e.g. 304)",
                  icon: Icons.door_front_door,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _floorController,
                  hint: "Floor (e.g. 3)",
                  icon: Icons.elevator,
                ),
                const Spacer(),
                GradientButton(
                  text: "Confirm & Continue",
                  onPressed: () {
                    final room = _roomController.text.trim();
                    if (room.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your room number')),
                      );
                      return;
                    }
                    context.go('/guest_home?room=$room');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: context.tc.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.tc.cardShadow,
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: AppTextStyles.body.copyWith(color: context.tc.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: context.tc.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
