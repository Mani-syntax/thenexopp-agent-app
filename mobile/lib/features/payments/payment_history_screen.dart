import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/state_widgets.dart';
import '../../shared/providers/dio_provider.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.payments);
      if (mounted && res.data['success'] == true) {
        setState(() {
          _payments = res.data['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProofDialog(String url, String txnId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment Proof ($txnId)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, height: 250, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('Proof image preview unavailable')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Receipts & Proofs')),
      body: _isLoading
          ? const LoadingSkeletonList()
          : _payments.isEmpty
              ? const EmptyStateWidget(title: 'No Payments Recorded', message: 'Payout receipts and bank transfer proofs will be listed here once recorded by admin.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final p = _payments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('₹${p['amount']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondaryGreen)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.secondaryGreenLight, borderRadius: BorderRadius.circular(6)),
                                  child: Text(p['status'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryGreenDark)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Transaction ID: ${p['transactionId']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Method: ${p['paymentMethod']} • Date: ${p['paidAt']?.substring(0, 10) ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                            if (p['paymentProofUrl'] != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _showProofDialog(p['paymentProofUrl'], p['transactionId']),
                                icon: const Icon(Icons.receipt_rounded, size: 16),
                                label: const Text('View Payment Proof Receipt'),
                                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 38)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
