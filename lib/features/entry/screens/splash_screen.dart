import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/session_provider.dart';
import '../widgets/animated_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait for the animation
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final session = Provider.of<SessionProvider>(context, listen: false);

    if (auth.currentUser != null) {
      try {
        final profile = await firestore.getStaffProfile(auth.currentUser!.uid);
        if (profile != null) {
          session.setSession(
            uid: auth.currentUser!.uid,
            name: profile.name,
            role: profile.role,
          );
          if (mounted) context.go('/command_dashboard');
          return;
        }
      } catch (e) {
        debugPrint("Session restoration failed: $e");
      }
    }

    if (mounted) context.go('/entry');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
        ),
        child: const Center(
          child: AnimatedLogo(),
        ),
      ),
    );
  }
}
