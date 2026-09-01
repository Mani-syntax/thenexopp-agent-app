import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/permission_service.dart';
import '../../shared/providers/dio_provider.dart';
import '../support/support_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAllAppPermissions(context);
    });
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Row(
                children: [
                  Icon(Icons.business_center_rounded, color: AppColors.primaryEmerald, size: 24),
                  SizedBox(width: 8),
                  Text('TheNexopp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark, size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryEmerald,
        onRefresh: _fetchDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agent Executive Card (White Card with Emerald Accent)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 20,
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
                                  const Text(
                                    'Welcome back,',
                                    style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _agentName,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.emeraldBorder),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, color: AppColors.primaryEmerald, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified Partner',
                                      style: TextStyle(
                                        color: AppColors.primaryEmeraldDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.borderSubtle, height: 1),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Net Earnings', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_totalEarnings.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.primaryEmerald,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pending Payout', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_pendingEarnings.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.accentGold,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Listings', style: TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_propertyCount Active',
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary CTA Button
                    ElevatedButton.icon(
                      onPressed: () => context.push('/properties/add'),
                      icon: const Icon(Icons.add_business_rounded, size: 20),
                      label: const Text('+ Add Property / Business Listing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        shadowColor: AppColors.primaryEmerald.withAlpha(100),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Performance Summary Section
                    const Text(
                      'Performance Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Paid Payouts',
                            '₹${_paidAmount.toStringAsFixed(0)}',
                            Icons.task_alt_rounded,
                            AppColors.primaryEmerald,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildMetricTile(
                            'Pending Verification',
                            '₹${_pendingEarnings.toStringAsFixed(0)}',
                            Icons.hourglass_top_rounded,
                            AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status & Compliance Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.emeraldBorder),
                            ),
                            child: const Icon(Icons.shield_outlined, color: AppColors.primaryEmerald, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KYC Identity Verification',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text('Account Status: $_kycStatus', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.emeraldBorder),
                            ),
                            child: const Text('APPROVED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryEmeraldDark)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Agent Support & Helpdesk Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryEmeraldDark, AppColors.primaryEmerald],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withAlpha(50),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Need Help or Face an Issue?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                                    SizedBox(height: 2),
                                    Text('Direct partner call desk & ticket filing', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                                  },
                                  icon: const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.primaryEmeraldDark),
                                  label: const Text('Raise Ticket / Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryEmeraldDark)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
