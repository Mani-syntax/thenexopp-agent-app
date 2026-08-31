import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/location_service.dart';
import '../../core/services/permission_service.dart';
import '../../shared/providers/dio_provider.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  String _category = 'RESIDENTIAL_RENT';
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  final List<Map<String, String>> _categories = [
    {'value': 'RESIDENTIAL_RENT', 'label': 'Residential Rent'},
    {'value': 'RESIDENTIAL_SALE', 'label': 'Residential Sale'},
    {'value': 'COMMERCIAL_RENT', 'label': 'Commercial Rent'},
    {'value': 'COMMERCIAL_SALE', 'label': 'Commercial Sale'},
    {'value': 'BUSINESS', 'label': 'Business Listing'},
  ];

  Future<void> _detectLiveLocation() async {
    final hasPermission = await PermissionService.checkAndRequestLocationPermission(context);
    if (!hasPermission && mounted) return;

    setState(() => _isDetectingLocation = true);
    final loc = await _locationService.fetchLiveOpenStreetMapLocation();
    setState(() => _isDetectingLocation = false);

    if (loc != null && loc.isNotEmpty) {
      _locationController.text = loc;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected OSM Location: $loc'), backgroundColor: AppColors.secondaryGreen),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission denied or unavailable. Please enter location manually.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    final hasPermission = await PermissionService.checkAndRequestStoragePermission(context);
    if (!hasPermission && mounted) return;

    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 75);
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _saveProperty(bool isDraft) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 photo'), backgroundColor: AppColors.statusError),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final List<String> uploadedKeys = [];

      for (final img in _selectedImages) {
        final presignedRes = await dio.post(ApiConstants.presignedUrl, data: {
          'bucketType': 'property-images',
          'filename': img.name,
          'mimeType': 'image/jpeg',
        });
        if (presignedRes.data['success'] == true) {
          uploadedKeys.add(presignedRes.data['data']['fileKey']);
        }
      }

      final response = await dio.post(ApiConstants.createProperty, data: {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _category,
        'location': _locationController.text.trim(),
        'imageKeys': uploadedKeys,
        'isDraft': isDraft,
      });

      if (response.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft ? 'Draft saved successfully' : 'Property submitted for verification!'),
            backgroundColor: AppColors.secondaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Check network or fields.'), backgroundColor: AppColors.statusError),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property Listing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Listing Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Property Title', hintText: 'e.g. 3BHK Apartment in Indiranagar'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter property title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'Details regarding space, amenities, terms...'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price / Rent (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                        validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid price' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))).toList(),
                        onChanged: (val) => setState(() => _category = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location with Dual Choice: Direct Manual Entry OR Live OpenStreetMap
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location / Area',
                    prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primaryNavy),
                    suffixIcon: _isDetectingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location_rounded, color: AppColors.secondaryGreen),
                            tooltip: 'Detect Live Location (OpenStreetMap)',
                            onPressed: _detectLiveLocation,
                          ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter location or use live GPS' : null,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Type directly above OR use live GPS', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    InkWell(
                      onTap: _isDetectingLocation ? null : _detectLiveLocation,
                      child: const Row(
                        children: [
                          Icon(Icons.map_rounded, size: 14, color: AppColors.secondaryGreen),
                          SizedBox(width: 4),
                          Text('Use Live OpenStreetMap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryGreenDark)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Image Picker & Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Property Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: const Text('Add Photos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _selectedImages.isEmpty
                    ? Container(
                        height: 100,
                        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight)),
                        child: const Center(child: Text('No photos selected yet', style: TextStyle(color: AppColors.textMedium))),
                      )
                    : SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(image: FileImage(File(_selectedImages[index].path)), fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedImages.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _saveProperty(true),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                        child: const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _saveProperty(false),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryGreen, minimumSize: const Size(0, 50)),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit for Review'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
