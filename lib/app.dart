import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/theme_notifier.dart';
import 'core/services/firestore_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/nearby_service.dart';
import 'core/services/storage_service.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/incident_provider.dart';
import 'core/providers/connectivity_provider.dart';

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => GeminiService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => NearbyService()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProxyProvider<ConnectivityService, ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
          update: (_, service, provider) => provider!..updateConnection(service.isOnline),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp.router(
            title: 'ResQ',
            debugShowCheckedModeBanner: false,
            themeMode: themeNotifier.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF5F5),
      cardColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D2D2D)),
        titleTextStyle: TextStyle(color: Color(0xFF2D2D2D), fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E2E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121218),
      cardColor: const Color(0xFF1E1E2E),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A28),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A3A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF2A2A3A),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A28),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white38,
      ),
      dividerColor: Colors.white12,
    );
  }
}
