import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/state_widgets.dart';
import '../../shared/providers/dio_provider.dart';
import '../payments/payment_history_screen.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _summary = {};
  List<dynamic> _earnings = [];

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.earnings);
      if (mounted && res.data['success'] == true) {
        setState(() {
          _summary = res.data['data']['summary'];
          _earnings = res.data['data']['earnings'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load earnings data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Earnings & Payout Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryNavy, size: 24),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const LoadingSkeletonList()
          : _errorMessage != null
              ? ErrorStateWidget(message: _errorMessage!, onRetry: _fetchEarnings)
              : RefreshIndicator(
                  color: AppColors.primaryEmerald,
                  onRefresh: _fetchEarnings,
                  child: ListView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Executive Gradient Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryNavyDark, AppColors.primaryNavy],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryNavyDark.withAlpha(50), blurRadius: 22, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Cumulative Earnings', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(
                              '₹${(_summary['totalEarnings'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.primaryEmeraldLight, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white12, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem('This Month', '₹${_summary['thisMonthEarnings'] ?? 0}'),
                                _buildSummaryItem('Pending Payout', '₹${_summary['pendingEarnings'] ?? 0}'),
                                _buildSummaryItem('Paid Out', '₹${_summary['paidAmount'] ?? 0}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Earning Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.3)),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
                            },
                            icon: const Icon(Icons.receipt_rounded, size: 16),
                            label: const Text('View Receipts'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_earnings.isEmpty)
                        const EmptyStateWidget(title: 'No Earnings Recorded', message: 'Earnings will appear here when properties are verified or work payouts are generated by administration.')
                      else
                        ..._earnings.map((e) {
                          final isPaid = e['status'] == 'PAID';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPaid ? AppColors.secondaryGreenLight : AppColors.accentGoldLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPaid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                                  color: isPaid ? AppColors.secondaryGreenDark : AppColors.accentGoldDark,
                                  size: 22,
                                ),
                              ),
                              title: Text(e['title'] ?? 'Earning Record', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                              subtitle: Text('Date: ${e['earnedDate']?.substring(0, 10) ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('+₹${e['amount']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isPaid ? AppColors.secondaryGreenDark : AppColors.textDark)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPaid ? AppColors.secondaryGreenLight : AppColors.accentGoldLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(e['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPaid ? AppColors.secondaryGreenDark : AppColors.accentGoldDark)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
