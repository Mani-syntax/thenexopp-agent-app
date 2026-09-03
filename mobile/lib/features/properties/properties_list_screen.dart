import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/state_widgets.dart';
import '../../shared/providers/dio_provider.dart';

class PropertiesListScreen extends ConsumerStatefulWidget {
  const PropertiesListScreen({super.key});

  @override
  ConsumerState<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends ConsumerState<PropertiesListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _properties = [];

  final List<String> _statuses = ['ALL', 'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchProperties();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _fetchProperties();
    }
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final selectedStatus = _statuses[_tabController.index];
      final dio = ref.read(dioClientProvider).dio;
      final statusParam = selectedStatus == 'ALL' ? '' : '?status=$selectedStatus';
      final response = await dio.get('${ApiConstants.properties}$statusParam');

      if (mounted) {
        setState(() {
          _properties = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load property listings';
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
        title: const Text('My Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryNavy, size: 26),
            onPressed: () => context.push('/properties/add'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primaryNavy,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Drafts'),
            Tab(text: 'Under Review'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingSkeletonList()
          : _errorMessage != null
              ? ErrorStateWidget(message: _errorMessage!, onRetry: _fetchProperties)
              : _properties.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Properties Found',
                      message: 'You have not submitted any property or business listings in this category.',
                      buttonText: '+ Add New Property',
                      onAction: () => context.push('/properties/add'),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        final prop = _properties[index];
                        final images = prop['images'] as List;
                        final imageUrl = images.isNotEmpty ? images.first['url'] : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => context.push('/properties/${prop['id']}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imageUrl != null
                                        ? Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover)
                                        : Container(
                                            width: 90,
                                            height: 90,
                                            color: AppColors.inputFill,
                                            child: const Icon(Icons.apartment_rounded, color: AppColors.textLight, size: 36),
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prop['title'] ?? 'Listing',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark, letterSpacing: -0.2),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${prop['price']} • ${prop['location']}',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            _buildStatusBadge(prop['status']),
                                            const SizedBox(width: 8),
                                            Text(
                                              prop['category']?.toString().replaceAll('_', ' ') ?? '',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.textMedium;
    Color border = AppColors.borderLight;

    if (status == 'APPROVED') {
      bg = AppColors.secondaryGreenLight;
      text = AppColors.secondaryGreenDark;
      border = AppColors.secondaryGreenBorder;
    } else if (status == 'SUBMITTED') {
      bg = AppColors.accentGoldLight;
      text = AppColors.accentGoldDark;
      border = AppColors.accentGoldBorder;
    } else if (status == 'REJECTED') {
      bg = Colors.red[50]!;
      text = AppColors.statusError;
      border = Colors.red[200]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
    );
  }
}
