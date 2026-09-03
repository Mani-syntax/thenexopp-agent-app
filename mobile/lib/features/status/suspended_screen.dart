import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/websocket_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/dio_provider.dart';

class SuspendedScreen extends ConsumerStatefulWidget {
  const SuspendedScreen({super.key});

  @override
  ConsumerState<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends ConsumerState<SuspendedScreen> {
  Timer? _statusPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketProvider).connect();
    });
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkLiveStatus());
  }

  Future<void> _checkLiveStatus() async {
    if (!mounted) return;
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.getProfile);
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final status = res.data['data']['status']?.toString();
        if (status == 'APPROVED') {
          _statusPollingTimer?.cancel();
          ref.read(authProvider.notifier).updateAgentState('APPROVED');
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, size: 72, color: AppColors.statusError),
              const SizedBox(height: 24),
              const Text(
                'Account Suspended',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your agent account has been suspended by administration due to policy compliance or verification review. Please reach out to official support.',
                style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Live sync active — Auto-restores when approved',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              OutlinedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout Securely'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  side: const BorderSide(color: AppColors.textMedium),
                  foregroundColor: AppColors.textMedium,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
