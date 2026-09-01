import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/location_service.dart';
import '../../core/services/permission_service.dart';
import '../../shared/providers/dio_provider.dart';
import '../../shared/providers/auth_provider.dart';

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends ConsumerState<ProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _ageController = TextEditingController();

  String _gender = 'Male';
  String _workPlatform = 'Swiggy';
  XFile? _profilePhotoFile;
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  final List<String> _platforms = ['Swiggy', 'Zomato', 'Rapido', 'Zepto', 'Blinkit', 'Individual'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAllAppPermissions(context);
    });
  }

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload Profile Photo / Selfie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Please select a clear photo of your face for agent identity verification.',
                style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final hasPerm = await PermissionService.checkAndRequestCameraPermission(context);
                        if (!hasPerm && mounted) return;
                        final XFile? photo = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 80);
                        if (photo != null && mounted) setState(() => _profilePhotoFile = photo);
                      },
                      icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryEmerald),
                      label: const Text('Take Selfie', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final hasPerm = await PermissionService.checkAndRequestStoragePermission(context);
                        if (!hasPerm && mounted) return;
                        final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (photo != null && mounted) setState(() => _profilePhotoFile = photo);
                      },
                      icon: const Icon(Icons.photo_library_rounded, color: AppColors.primaryEmerald),
                      label: const Text('From Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto(XFile file) async {
    final dio = ref.read(dioClientProvider).dio;
    final res = await dio.post(ApiConstants.presignedUrl, data: {
      'bucketType': 'private-kyc',
      'filename': file.name,
      'mimeType': 'image/jpeg',
    });

    if (res.data['success'] == true) {
      final fileKey = res.data['data']['fileKey'];
      return fileKey;
    }
    return null;
  }

  Future<void> _detectLiveLocation() async {
    setState(() => _isDetectingLocation = true);
    final loc = await _locationService.fetchLiveOpenStreetMapLocation();
    setState(() => _isDetectingLocation = false);

    if (loc != null && loc.isNotEmpty) {
      _areaController.text = loc;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected OSM Location: $loc'), backgroundColor: AppColors.primaryEmerald),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission denied or unavailable. Please enter area manually.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profilePhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a selfie or upload your profile photo to continue.'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final photoKey = await _uploadPhoto(_profilePhotoFile!);

      final response = await dio.put(ApiConstants.updateProfile, data: {
        'fullName': _nameController.text.trim(),
        'areaLocation': _areaController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _gender,
        'workPlatform': _workPlatform,
        'profilePhotoUrl': photoKey,
      });

      if (response.data['success'] == true && mounted) {
        ref.read(authProvider.notifier).updateAgentState('KYC_INCOMPLETE');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile. Please retry.'), backgroundColor: AppColors.statusError),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Agent Profile (Step 1 of 3)')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(value: 0.33, backgroundColor: AppColors.borderLight, color: AppColors.primaryEmerald),
                const SizedBox(height: 24),
                const Text('Personal & Work Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                const Text('Upload your clear face photo and enter details to register your agent account.', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                const SizedBox(height: 24),

                // Agent Photo Picker
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emeraldSurface,
                            border: Border.all(color: AppColors.emeraldBorder, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ClipOval(
                            child: _profilePhotoFile != null
                                ? Image.file(
                                    File(_profilePhotoFile!.path),
                                    width: 104,
                                    height: 104,
                                    fit: BoxFit.cover,
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_alt_1_rounded, size: 36, color: AppColors.primaryEmerald),
                                      SizedBox(height: 4),
                                      Text('Add Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryEmeraldDark)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _profilePhotoFile != null ? 'Photo Selected (Tap to Change)' : 'Take Selfie or Upload Photo *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _profilePhotoFile != null ? AppColors.primaryEmerald : AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded)),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _areaController,
                  decoration: InputDecoration(
                    labelText: 'Area / Operating Location',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    suffixIcon: _isDetectingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location_rounded, color: AppColors.primaryEmerald),
                            tooltip: 'Use Live OpenStreetMap Location',
                            onPressed: _detectLiveLocation,
                          ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter operating location or use live GPS' : null,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Type directly above OR use live GPS', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    InkWell(
                      onTap: _isDetectingLocation ? null : _detectLiveLocation,
                      child: const Text('Use Live OpenStreetMap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryEmeraldDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_rounded)),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter age';
                    final age = int.tryParse(val);
                    if (age == null || age < 18 || age > 80) return 'Age must be between 18 and 80';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_rounded)),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _gender = val!),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _workPlatform,
                  decoration: const InputDecoration(labelText: 'Primary Work Platform', prefixIcon: Icon(Icons.work_rounded)),
                  items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setState(() => _workPlatform = val!),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Continue to KYC'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
