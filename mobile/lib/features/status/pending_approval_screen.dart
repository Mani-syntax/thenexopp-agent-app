import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/human_agent_logo.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/websocket_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/dio_provider.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  Timer? _statusPollingTimer;

  @override
  void initState() {
    super.initState();
    // Connect WebSocket stream for immediate real-time event dispatch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketProvider).connect();
    });

    // 2-second background status poller for 100% guarantee
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
        } else if (status == 'REJECTED') {
          _statusPollingTimer?.cancel();
          final reason = res.data['data']['rejectionReason']?.toString();
          ref.read(authProvider.notifier).updateAgentState('REJECTED', rejectionReason: reason);
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
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HumanAgentLogo(size: 110),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.accentGoldLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, size: 48, color: AppColors.accentGoldDark),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application Under Review',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your profile, KYC documents, and bank details have been submitted. Our administration team is currently verifying your records.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Live Stream Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryEmerald.withAlpha(40)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Live sync connected — Auto-unlocks on Admin approval',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryEmeraldDark),
                          textAlign: TextAlign.center,
                        ),
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
                    minimumSize: const Size(200, 48),
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
