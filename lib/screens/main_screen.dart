import 'dart:ui';
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

class MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final _historyKey = GlobalKey<HistoryScreenState>();
  late AnimationController _navAnim;

  void goHome() {
    setState(() => _currentIndex = 0);
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _screens = [
      const HomeScreen(),
      HistoryScreen(key: _historyKey, onGoHome: goHome),
      SettingsScreen(onGoHome: goHome),
    ];
  }

  @override
  void dispose() {
    _navAnim.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _navAnim.forward(from: 0);
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
          color: LKTheme.bgCard.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: LKTheme.border.withValues(alpha: 0.3))),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(Icons.home_rounded, 'Home', 0),
                    _navItem(Icons.people_rounded, 'People', 1),
                    _navItem(Icons.tune_rounded, 'Set Up', 2),
                  ],
                ),
              ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? LKTheme.gold.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: isSelected ? 28 : 24,
                color: isSelected ? LKTheme.gold : LKTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? LKTheme.gold : LKTheme.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
