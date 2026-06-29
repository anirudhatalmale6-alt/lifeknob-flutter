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

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (index == 1) {
      _historyKey.currentState?.ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onTabChange: _onTabChanged),
      HistoryScreen(key: _historyKey, onGoHome: goHome, onTabChange: _onTabChanged),
      SettingsScreen(onGoHome: goHome),
    ];

    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
