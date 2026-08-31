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
    return Scaffold(
      appBar: AppBar(title: const Text('Property Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _property == null
              ? const Center(child: Text('Property not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images Carousel / Main Image
                      if ((_property!['images'] as List).isNotEmpty)
                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            itemCount: (_property!['images'] as List).length,
                            itemBuilder: (context, index) {
                              final imgUrl = _property!['images'][index]['url'];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(imgUrl, fit: BoxFit.cover, width: double.infinity),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(_property!['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ),
                          Text('₹${_property!['price']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryNavy),
                          const SizedBox(width: 4),
                          Text(_property!['location'], style: const TextStyle(color: AppColors.textMedium)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rejection Alert if REJECTED
                      if (_property!['status'] == 'REJECTED') ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('REJECTION REASON FROM ADMIN:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusError, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(_property!['rejectionReason'] ?? 'Details failed verification.', style: const TextStyle(color: AppColors.textDark)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_property!['description'], style: const TextStyle(color: AppColors.textMedium, height: 1.5)),
                      const SizedBox(height: 24),

                      if (_property!['status'] == 'DRAFT')
                        ElevatedButton(
                          onPressed: () async {
                            final dio = ref.read(dioClientProvider).dio;
                            await dio.post(ApiConstants.submitProperty(widget.propertyId));
                            _fetchDetails();
                          },
                          child: const Text('Submit Draft for Verification'),
                        ),
                    ],
                  ),
                ),
    );
  }
}
