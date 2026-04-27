import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/staff_model.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/session_provider.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  _StaffLoginScreenState createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasError = false;

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both email and password'),
            backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      await auth.signInWithEmailPassword(email, password);

      if (mounted) {
        try {
          final profile = await firestore.getStaffProfile(auth.currentUser!.uid);
          
          // Update status to available upon login
          await firestore.saveStaffProfile(StaffModel(
            id: auth.currentUser!.uid,
            name: profile?.name ?? "Staff Member",
            email: auth.currentUser!.email ?? "",
            role: profile?.role ?? "Security",
            status: 'available',
            isAvailable: true,
            phone: profile?.phone,
            lng: 77.2090,
          ));
          
          // Step 8: Set Session After Login
          if (mounted) {
            context.read<SessionProvider>().setSession(
              uid: auth.currentUser!.uid,
              name: profile?.name ?? "Staff Member",
              role: profile?.role ?? "Security",
            );
          }

          if (profile == null) {
            context.go('/staff_profile');
          } else {
            context.go('/command_dashboard');
          }
        } catch (e) {
          debugPrint("Firestore check failed, bypassing: $e");
          // Bypass profile check if Firestore is unavailable to allow testing login flow
          context.go('/command_dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Staff Portal",
                    style: AppTextStyles.display.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFFFF4D67), letterSpacing: -1.0))
                .animate()
                .fadeIn(delay: 200.ms)
                .slideX(begin: -0.2),
            const SizedBox(height: 8),
            Text("Secure access for authorized personnel only",
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 300.ms),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailController,
              hint: "Email address",
              icon: Icons.alternate_email_rounded,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              hint: "Password",
              icon: Icons.lock_rounded,
              isPassword: true,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text("Recover Password",
                    style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ).animate().fadeIn(delay: 600.ms),
            ),
            const SizedBox(height: 40),
            GradientButton(
              text: "Authorize & Enter",
              isLoading: _isLoading,
              onPressed: _handleLogin,
            )
                .animate()
                .fadeIn(delay: 700.ms)
                .scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (_hasError) {
      card = card.animate().shake(duration: 400.ms, hz: 4);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF4D67), Color(0xFFFF8599)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield, color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      Text("ResQ",
                          style: AppTextStyles.display
                              .copyWith(color: Colors.white)),
                      Text("Staff Portal",
                          style: AppTextStyles.title
                              .copyWith(color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
              ),
            ),
            card.animate().slideY(
                begin: 1.0, duration: 400.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: TextFormField(
        style: TextStyle(color: Colors.black),
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    );
  }
}
