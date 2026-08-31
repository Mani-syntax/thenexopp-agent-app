import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/human_agent_logo.dart';
import '../../shared/providers/websocket_provider.dart';
import '../../shared/providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure WebSocket is active to listen for real-time status changes
    ref.read(webSocketProvider).connect();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HumanAgentLogo(size: 130),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.accentGoldLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 54, color: AppColors.accentGoldDark),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, size: 16, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Text(
                      'Live updates active — No manual refresh needed',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout Securely'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  side: const BorderSide(color: AppColors.textMedium),
                  foregroundColor: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
