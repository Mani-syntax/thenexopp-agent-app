import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/state_widgets.dart';
import '../../shared/providers/dio_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(ApiConstants.notifications);
      if (mounted && res.data['success'] == true) {
        setState(() {
          _unreadCount = res.data['data']['unreadCount'] ?? 0;
          _notifications = res.data['data']['notifications'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.put(ApiConstants.markAllRead);
      _fetchNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts & Updates ($_unreadCount New)'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark All Read', style: TextStyle(color: AppColors.accentGold)),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingSkeletonList()
          : _notifications.isEmpty
              ? const EmptyStateWidget(title: 'No Notifications', message: 'Updates regarding KYC approval, property verifications, and payments will appear here.')
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final isRead = item['isRead'] == true;

                      return Card(
                        color: isRead ? Colors.white : AppColors.primaryNavy.withAlpha(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead ? Colors.grey[200] : AppColors.primaryNavy,
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: isRead ? AppColors.textMedium : AppColors.accentGold,
                              size: 20,
                            ),
                          ),
                          title: Text(item['title'] ?? 'Notification', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(item['message'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                              const SizedBox(height: 4),
                              Text(item['createdAt']?.substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
