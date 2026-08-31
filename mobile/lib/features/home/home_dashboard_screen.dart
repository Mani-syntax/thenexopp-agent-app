import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/dio_provider.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  bool _isLoading = true;
  String _agentName = 'Agent Partner';
  double _totalEarnings = 0;
  double _pendingEarnings = 0;
  double _paidAmount = 0;
  int _propertyCount = 0;
  String _kycStatus = 'APPROVED';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final profileRes = await dio.get(ApiConstants.getProfile);
      final earningsRes = await dio.get(ApiConstants.earnings);
      final propertiesRes = await dio.get(ApiConstants.properties);

      if (mounted) {
        setState(() {
          if (profileRes.data['success'] == true) {
            final p = profileRes.data['data']['profile'];
            if (p != null) _agentName = p['fullName'] ?? 'Agent Partner';
            _kycStatus = profileRes.data['data']['kycStatus'] ?? 'APPROVED';
          }

          if (earningsRes.data['success'] == true) {
            final summary = earningsRes.data['data']['summary'];
            _totalEarnings = (summary['totalEarnings'] ?? 0).toDouble();
            _pendingEarnings = (summary['pendingEarnings'] ?? 0).toDouble();
            _paidAmount = (summary['paidAmount'] ?? 0).toDouble();
          }

          if (propertiesRes.data['success'] == true) {
            final list = propertiesRes.data['data'] as List;
            _propertyCount = list.length;
          }

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.business_center_rounded)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryNavy),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agent Greeting Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryNavy, AppColors.primaryNavyLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNavy.withAlpha(30),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  Text(
                                    _agentName,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryGreen.withAlpha(40),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.secondaryGreenBorder.withAlpha(100)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('Verified Agent', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Net Earnings', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                  Text(
                                    '₹${_totalEarnings.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.accentGold, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pending Payout', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                  Text(
                                    '₹${_pendingEarnings.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Listings', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                  Text(
                                    '$_propertyCount Active',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary CTA Button
                    ElevatedButton.icon(
                      onPressed: () => context.push('/properties/add'),
                      icon: const Icon(Icons.add_business_rounded, size: 22),
                      label: const Text('+ Add Property / Business Listing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryGreen,
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 2,
                        shadowColor: AppColors.secondaryGreen.withAlpha(60),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Executive Metric Grid Cards
                    const Text('Performance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.3)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildMetricTile('Paid Payouts', '₹${_paidAmount.toStringAsFixed(0)}', Icons.task_alt_rounded, AppColors.secondaryGreen)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildMetricTile('Pending Verification', '₹${_pendingEarnings.toStringAsFixed(0)}', Icons.hourglass_top_rounded, AppColors.accentGold)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Status & Compliance Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGreenLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: AppColors.secondaryGreen, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('KYC Identity Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text('Identity Status: $_kycStatus', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGreenLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.secondaryGreenBorder),
                            ),
                            child: const Text('APPROVED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryGreenDark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
