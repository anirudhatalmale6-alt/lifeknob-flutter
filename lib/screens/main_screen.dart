import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void goHome() {
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      HistoryScreen(onGoHome: goHome),
      SettingsScreen(onGoHome: goHome),
    ];

    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: LKTheme.bgCard,
          border: Border(top: BorderSide(color: LKTheme.border.withValues(alpha: 0.5))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.dashboard_rounded, 'DASHBOARD', 0),
                _navItem(Icons.list_alt_rounded, 'LOGS', 1),
                _navItem(Icons.settings_rounded, 'SYSTEMS', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? LKTheme.gold : LKTheme.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? LKTheme.gold : LKTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: LKTheme.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
