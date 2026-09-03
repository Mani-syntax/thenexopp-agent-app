import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/state_widgets.dart';
import '../../shared/providers/dio_provider.dart';
import '../../shared/providers/websocket_provider.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _payments = [];
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPayments();

    Future.microtask(() {
      final ws = ref.read(webSocketProvider);
      ws.connect();
      _wsSubscription = ws.events.listen((event) {
        if (event['event'] == 'payment.created' || event['event'] == 'payment.deleted') {
          _fetchPayments();
        }
      });
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
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

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $month ${dt.year} • ${hour.toString().padLeft(2, '0')}:$min $period';
    } catch (_) {
      return dateStr.toString();
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
              child: Image.network(
                url,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Text('Proof image preview unavailable'),
              ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Payment Receipts & Proofs'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingSkeletonList()
          : _payments.isEmpty
              ? const EmptyStateWidget(
                  title: 'No Payments Recorded',
                  message: 'Payout receipts and bank transfer proofs with complete timestamps will be listed here once recorded by administration.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final p = _payments[index];
                    final isCompleted = p['status'] == 'COMPLETED';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Amount & Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${p['amount']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryEmerald,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCompleted ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Text(
                                    p['status'] ?? 'COMPLETED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isCompleted ? const Color(0xFF047857) : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.borderLight, height: 1),
                            const SizedBox(height: 12),

                            // Transaction ID
                            Row(
                              children: [
                                const Text(
                                  'Transaction ID: ',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  p['transactionId'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Payment Method & Live Timestamp with Clock
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Text(
                                    p['paymentMethod'] ?? 'NEFT',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(p['paidAt']),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Proof Button if Available
                            if (p['paymentProofUrl'] != null) ...[
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () => _showProofDialog(p['paymentProofUrl'], p['transactionId']),
                                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primaryEmerald),
                                label: const Text('View Official Payment Proof Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
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
