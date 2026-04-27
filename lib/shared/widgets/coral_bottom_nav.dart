import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CoralBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CoralBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Incidents'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Team'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Audit'),
        ],
      ),
    );
  }
}
