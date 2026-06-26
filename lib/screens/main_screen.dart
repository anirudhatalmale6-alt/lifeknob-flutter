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
  final _historyKey = GlobalKey<HistoryScreenState>();

  void goHome() {
    setState(() => _currentIndex = 0);
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      HistoryScreen(key: _historyKey, onGoHome: goHome),
      SettingsScreen(onGoHome: goHome),
    ];
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      _historyKey.currentState?.ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
                _navItem(Icons.home_rounded, 'Home', 0),
                _navItem(Icons.people_rounded, 'People', 1),
                _navItem(Icons.settings_rounded, 'Set Up', 2),
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
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: isSelected ? LKTheme.gold : LKTheme.textMuted),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? LKTheme.gold : LKTheme.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold),
            ),
          ],
        ),
      ),
    );
  }
}
