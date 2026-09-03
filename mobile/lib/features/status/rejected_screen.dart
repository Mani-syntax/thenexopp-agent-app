import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/websocket_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/dio_provider.dart';

class RejectedScreen extends ConsumerStatefulWidget {
  const RejectedScreen({super.key});

  @override
  ConsumerState<RejectedScreen> createState() => _RejectedScreenState();
}

class _RejectedScreenState extends ConsumerState<RejectedScreen> {
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
    final reason = ref.watch(authProvider).rejectionReason ?? 'Document or profile validation failed.';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.statusError.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gpp_bad_rounded, size: 64, color: AppColors.statusError),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Application Action Required',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ADMINISTRATIVE REASON:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusError),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reason,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                        'Live sync connected — Auto-unlocks when approved',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).updateAgentState('PROFILE_INCOMPLETE');
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Edit Details & Resubmit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
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
      ),
    );
  }
}
