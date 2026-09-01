import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/websocket_provider.dart';
import 'home_dashboard_screen.dart';
import '../properties/properties_list_screen.dart';
import '../earnings/earnings_screen.dart';
import '../support/support_screen.dart';
import '../profile/profile_screen.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeDashboardScreen(),
    PropertiesListScreen(),
    EarningsScreen(),
    SupportScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Connect WebSocket gateway for background notifications and status pushes
    Future.microtask(() => ref.read(webSocketProvider).connect());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primaryEmerald,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: -0.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.dashboard_rounded)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_work_rounded)),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_balance_wallet_rounded)),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.support_agent_rounded)),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
