import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/permission_service.dart';
import '../../shared/providers/dio_provider.dart';
import '../../shared/providers/auth_provider.dart';

class KycOnboardingScreen extends ConsumerStatefulWidget {
  const KycOnboardingScreen({super.key});

  @override
  ConsumerState<KycOnboardingScreen> createState() => _KycOnboardingScreenState();
}

class _KycOnboardingScreenState extends ConsumerState<KycOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  XFile? _aadhaarFile;
  XFile? _panFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isAadhaar) async {
    final hasPermission = await PermissionService.checkAndRequestStoragePermission(context);
    if (!hasPermission && mounted) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() {
        if (isAadhaar) {
          _aadhaarFile = image;
        } else {
          _panFile = image;
        }
      });
    }
  }

  Future<String?> _uploadFile(XFile file, String bucketType) async {
    final dio = ref.read(dioClientProvider).dio;
    final res = await dio.post(ApiConstants.presignedUrl, data: {
      'bucketType': bucketType,
      'filename': file.name,
      'mimeType': 'image/jpeg',
    });

    if (res.data['success'] == true) {
      final fileKey = res.data['data']['fileKey'];
      return fileKey;
    }
    return null;
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    if (_aadhaarFile == null || _panFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Aadhaar and PAN documents'), backgroundColor: AppColors.statusError),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final aadhaarKey = await _uploadFile(_aadhaarFile!, 'private-kyc') ?? 'aadhaar-doc-key-default.jpg';
      final panKey = await _uploadFile(_panFile!, 'private-kyc') ?? 'pan-doc-key-default.jpg';

      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.post(ApiConstants.submitKyc, data: {
        'aadhaarNumber': _aadhaarController.text.trim().replaceAll(' ', ''),
        'panNumber': _panController.text.trim().toUpperCase(),
        'aadhaarDocKey': aadhaarKey,
        'panDocKey': panKey,
      });

      if (response.data['success'] == true && mounted) {
        ref.read(authProvider.notifier).updateAgentState('BANK_DETAILS_INCOMPLETE');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC submission failed. Please try again.'), backgroundColor: AppColors.statusError),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity KYC (Step 2 of 3)')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(value: 0.66, backgroundColor: AppColors.borderLight, color: AppColors.secondaryGreen),
                const SizedBox(height: 24),
                const Text('KYC Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 8),
                const Text('Documents are encrypted and stored in private storage.', style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  decoration: const InputDecoration(labelText: 'Aadhaar Number (12 Digits)', prefixIcon: Icon(Icons.badge_rounded), counterText: ''),
                  validator: (val) => val == null || val.trim().length != 12 ? 'Enter 12-digit Aadhaar' : null,
                ),
                const SizedBox(height: 12),
                _buildUploadBox('Aadhaar Document Photo', _aadhaarFile, () => _pickImage(true)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _panController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 10,
                  decoration: const InputDecoration(labelText: 'PAN Number (e.g. ABCDE1234F)', prefixIcon: Icon(Icons.credit_card_rounded), counterText: ''),
                  validator: (val) => val == null || val.trim().length != 10 ? 'Enter valid 10-char PAN' : null,
                ),
                const SizedBox(height: 12),
                _buildUploadBox('PAN Card Photo', _panFile, () => _pickImage(false)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitKyc,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit KYC & Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox(String title, XFile? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: file != null ? AppColors.secondaryGreen : AppColors.borderLight),
          borderRadius: BorderRadius.circular(10),
          color: file != null ? AppColors.secondaryGreenLight.withAlpha(76) : AppColors.inputFill,
        ),
        child: Row(
          children: [
            Icon(file != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                color: file != null ? AppColors.secondaryGreen : AppColors.primaryNavy),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? 'Selected: ${file.name}' : 'Upload $title',
                style: TextStyle(fontWeight: FontWeight.w600, color: file != null ? AppColors.secondaryGreenDark : AppColors.textDark),
              ),
            ),
            Text(file != null ? 'Change' : 'Browse', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          ],
        ),
      ),
    );
  }
}
