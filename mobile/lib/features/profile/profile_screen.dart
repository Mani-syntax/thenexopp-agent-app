import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/dio_provider.dart';
import '../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _agentData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.getProfile);
      if (mounted && res.data['success'] == true) {
        setState(() {
          _agentData = res.data['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _agentData?['profile'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Agent Account Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.statusError),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Avatar & Verified Badge Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavySurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primaryNavy,
                          child: Text(
                            profile?['fullName']?.substring(0, 1).toUpperCase() ?? 'A',
                            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          profile?['fullName'] ?? 'Agent Name',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+91 ${_agentData?['mobileNumber'] ?? ''}',
                          style: const TextStyle(color: AppColors.textMedium, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatusPill('KYC: ${_agentData?['kycStatus']}', AppColors.secondaryGreen, AppColors.secondaryGreenLight),
                            const SizedBox(width: 10),
                            _buildStatusPill('Bank: ${_agentData?['bankStatus']}', AppColors.primaryNavy, AppColors.primaryNavySurface),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.location_on_rounded, 'Operating Location', profile?['areaLocation'] ?? 'N/A'),
                        const Divider(color: AppColors.borderLight, height: 24),
                        _buildDetailRow(Icons.work_rounded, 'Work Platform', profile?['workPlatform'] ?? 'Individual'),
                        const Divider(color: AppColors.borderLight, height: 24),
                        _buildDetailRow(Icons.cake_rounded, 'Age & Gender', '${profile?['age'] ?? 'N/A'} yrs • ${profile?['gender'] ?? ''}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions & Security Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.shield_rounded, color: AppColors.primaryNavy),
                          title: const Text('Masked KYC Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Aadhaar: XXXX XXXX 1234 • PAN: XXXXX1234X', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: () {},
                        ),
                        const Divider(color: AppColors.borderLight, height: 1),
                        ListTile(
                          leading: const Icon(Icons.account_balance_rounded, color: AppColors.primaryNavy),
                          title: const Text('Masked Bank & Payout Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Account: XXXX XXXX 4521 • Verified', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: () {},
                        ),
                        const Divider(color: AppColors.borderLight, height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline_rounded, color: AppColors.primaryNavy),
                          title: const Text('Agent Help & Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: () {},
                        ),
                        const Divider(color: AppColors.borderLight, height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined, color: AppColors.primaryNavy),
                          title: const Text('Terms & Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.statusError),
                    label: const Text('Logout Securely', style: TextStyle(color: AppColors.statusError)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.statusError, width: 1.5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusPill(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(60))),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryNavy),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
      ],
    );
  }
}
