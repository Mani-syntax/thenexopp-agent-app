import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/dio_provider.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _property;
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('${ApiConstants.properties}/${widget.propertyId}');
      if (mounted && res.data['success'] == true) {
        setState(() {
          _property = res.data['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _property?['images'] as List? ?? [];
    final specs = _property?['specifications'] as Map<String, dynamic>? ?? {};
    final category = _property?['category']?.toString() ?? 'RESIDENTIAL_RENT';
    final status = _property?['status']?.toString() ?? 'DRAFT';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Listing Details'),
        actions: [
          _buildStatusBadge(status),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _property == null
              ? const Center(child: Text('Listing details could not be found'))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Photos Carousel
                      if (images.isNotEmpty) ...[
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                height: 230,
                                child: PageView.builder(
                                  itemCount: images.length,
                                  onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                                  itemBuilder: (context, index) {
                                    final imgUrl = images[index]['url'];
                                    return Image.network(
                                      imgUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.inputFillSubtle,
                                        child: const Center(child: Icon(Icons.apartment_rounded, size: 48, color: AppColors.textLight)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(140),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_activeImageIndex + 1} / ${images.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 2. Category Pill & Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCategoryPill(category),
                          Text(
                            '₹${_property!['price']}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryEmerald,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 3. Title
                      Text(
                        _property!['title'] ?? 'Property Listing',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 6),

                      // 4. Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryEmerald),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _property!['location'] ?? 'Location N/A',
                              style: const TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.borderLight, height: 1),
                      const SizedBox(height: 18),

                      // 5. Dynamic Category Specifications Grid
                      if (specs.isNotEmpty) ...[
                        const Text('Specifications & Key Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: _buildDynamicSpecsView(category, specs),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 6. Rejection Alert if REJECTED
                      if (_property!['status'] == 'REJECTED') ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 18),
                                  SizedBox(width: 6),
                                  Text('ADMIN VERIFICATION FEEDBACK:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusError, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_property!['rejectionReason'] ?? 'Details require revision before approval.', style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 7. Description
                      const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Text(
                        _property!['description'] ?? '',
                        style: const TextStyle(color: AppColors.textMedium, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 28),

                      // 8. Submit Draft Button if DRAFT
                      if (_property!['status'] == 'DRAFT')
                        ElevatedButton.icon(
                          onPressed: () async {
                            final dio = ref.read(dioClientProvider).dio;
                            await dio.post(ApiConstants.submitProperty(widget.propertyId));
                            _fetchDetails();
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Submit Draft for Administrative Review', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064E3B),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDynamicSpecsView(String category, Map<String, dynamic> specs) {
    final List<Widget> items = [];

    specs.forEach((key, val) {
      if (val == null || val.toString().isEmpty) return;
      if (key == 'amenities' || key == 'includedAssets') {
        final list = val is List ? val : [];
        if (list.isNotEmpty) {
          items.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key == 'amenities' ? 'Amenities' : 'Included Assets',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: list.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(item.toString(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primaryEmeraldDark)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSpecKey(key),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                ),
                Text(
                  val.toString(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  String _formatSpecKey(String key) {
    switch (key) {
      case 'bhk':
        return 'Configuration';
      case 'furnishing':
        return 'Furnishing Status';
      case 'deposit':
        return 'Security Deposit';
      case 'areaSqFt':
        return 'Super Area (sq.ft)';
      case 'carpetAreaSqFt':
        return 'Carpet Area';
      case 'tenantPreference':
        return 'Preferred Tenants';
      case 'propertyType':
        return 'Property Type';
      case 'possession':
        return 'Possession Status';
      case 'ownership':
        return 'Ownership Khata';
      case 'commercialType':
        return 'Commercial Space Type';
      case 'lockInPeriod':
        return 'Lock-in Period';
      case 'seats':
        return 'Seating Capacity';
      case 'sector':
        return 'Industry Sector';
      case 'dealType':
        return 'Deal / Transfer Type';
      case 'monthlyRevenue':
        return 'Monthly Revenue';
      case 'monthlyProfit':
        return 'Monthly Net Profit';
      case 'establishedYear':
        return 'Inception Year';
      case 'employees':
        return 'Employees';
      default:
        return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').capitalize();
    }
  }

  Widget _buildCategoryPill(String category) {
    String label = category.replaceAll('_', ' ');
    Color color = AppColors.primaryEmerald;
    Color bg = AppColors.emeraldSurface;

    if (category.contains('RENT')) {
      color = const Color(0xFF059669);
      bg = const Color(0xFFECFDF5);
    } else if (category.contains('SALE')) {
      color = const Color(0xFF2563EB);
      bg = const Color(0xFFEFF6FF);
    } else if (category == 'BUSINESS') {
      color = const Color(0xFFE11D48);
      bg = const Color(0xFFFFF1F2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withAlpha(60))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.accentGold;
    Color bg = AppColors.accentGoldLight;

    if (status == 'APPROVED') {
      color = AppColors.primaryEmerald;
      bg = AppColors.emeraldSurface;
    } else if (status == 'REJECTED') {
      color = AppColors.statusError;
      bg = const Color(0xFFFFF1F2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withAlpha(60))),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
