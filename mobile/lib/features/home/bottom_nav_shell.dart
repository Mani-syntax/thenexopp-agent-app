import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/websocket_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/dio_provider.dart';
import '../../shared/providers/bottom_nav_provider.dart';
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
  Timer? _statusPollingTimer;

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
    Future.microtask(() => ref.read(webSocketProvider).connect());
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkLiveStatus());
  }

  Future<void> _checkLiveStatus() async {
    if (!mounted) return;
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.getProfile);
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final status = res.data['data']['status']?.toString();
        if (status != null && status != 'APPROVED') {
          _statusPollingTimer?.cancel();
          final reason = res.data['data']['rejectionReason']?.toString();
          ref.read(authProvider.notifier).updateAgentState(status, rejectionReason: reason);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.09),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(33),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(33),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.75),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDockItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home', currentIndex),
                    _buildDockItem(1, Icons.domain_rounded, Icons.domain_outlined, 'Listings', currentIndex),
                    _buildDockItem(2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Earnings', currentIndex),
                    _buildDockItem(3, Icons.headset_mic_rounded, Icons.headset_mic_outlined, 'Contact', currentIndex),
                    _buildDockItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile', currentIndex),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData activeIcon, IconData inactiveIcon, String label, int currentIndex) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(bottomNavIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isSelected ? AppColors.obsidianBlack : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.obsidianBlack.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textMedium,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
