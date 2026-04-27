import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/entry/screens/splash_screen.dart';
import '../../features/entry/screens/entry_screen.dart';
import '../../features/guest/screens/nfc_scan_screen.dart';
import '../../features/guest/screens/qr_scanner_screen.dart';
import '../../features/guest/screens/manual_entry_screen.dart';
import '../../features/guest/screens/guest_home_screen.dart';
import '../../features/guest/widgets/countdown_overlay.dart';
import '../../features/guest/screens/sos_trigger_screen.dart';
import '../../features/guest/screens/status_tracking_screen.dart';
import '../../features/guest/screens/incoming_call_screen.dart';
import '../../features/staff/screens/staff_login_screen.dart';
import '../../features/staff/screens/command_dashboard_screen.dart';
import '../../features/staff/screens/incident_detail_screen.dart';
import '../../features/staff/screens/outgoing_call_screen.dart';
import '../../features/staff/screens/staff_profile_screen.dart';
import '../../features/responder/responder_portal_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/entry',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EntryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/nfc_scan',
      builder: (context, state) => const NfcScanScreen(),
    ),
    GoRoute(
      path: '/qr_scan',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/manual_entry',
      builder: (context, state) => const ManualEntryScreen(),
    ),
    GoRoute(
      path: '/guest_home',
      builder: (context, state) {
        final room = state.uri.queryParameters['room'] ?? '???';
        return GuestHomeScreen(roomNumber: room);
      },
    ),
    GoRoute(
      path: '/countdown',
      pageBuilder: (context, state) {
        final room = state.uri.queryParameters['room'] ?? '???';
        return CustomTransitionPage(
          key: state.pageKey,
          child: CountdownOverlay(roomNumber: room),
          opaque: false,
          barrierColor: Colors.black54,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/sos_trigger',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'];
        final room = state.uri.queryParameters['room'] ?? '???';
        return SosTriggerScreen(initialType: type, roomNumber: room);
      },
    ),
    GoRoute(
      path: '/status_tracking',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'] ?? 'other';
        final id = state.uri.queryParameters['id'];
        final room = state.uri.queryParameters['room'] ?? '???';
        return StatusTrackingScreen(
            incidentType: type, incidentId: id, roomNumber: room);
      },
    ),
    GoRoute(
      path: '/incoming_call',
      builder: (context, state) => const IncomingCallScreen(),
    ),
    GoRoute(
      path: '/staff_login',
      builder: (context, state) => const StaffLoginScreen(),
    ),
    GoRoute(
      path: '/command_dashboard',
      builder: (context, state) => const CommandDashboardScreen(),
    ),
    GoRoute(
      path: '/incident_detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return IncidentDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/outgoing_call',
      builder: (context, state) => const OutgoingCallScreen(),
    ),
    GoRoute(
      path: '/staff_profile',
      builder: (context, state) => const StaffProfileScreen(),
    ),
    GoRoute(
      path: '/responder_portal/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ResponderPortalScreen(incidentId: id);
      },
    ),
  ],
);
