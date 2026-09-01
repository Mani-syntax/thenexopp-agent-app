import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  final LocationService _locationService = LocationService();

  final List<String> _platforms = ['Swiggy', 'Zomato', 'Rapido', 'Zepto', 'Blinkit', 'Individual'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAllAppPermissions(context);
    });
  }

  Future<void> _detectLiveLocation() async {
    setState(() => _isDetectingLocation = true);
    final loc = await _locationService.fetchLiveOpenStreetMapLocation();
    setState(() => _isDetectingLocation = false);

    if (loc != null && loc.isNotEmpty) {
      _areaController.text = loc;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected OSM Location: $loc'), backgroundColor: AppColors.secondaryGreen),
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
    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.put(ApiConstants.updateProfile, data: {
        'fullName': _nameController.text.trim(),
        'areaLocation': _areaController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _gender,
        'workPlatform': _workPlatform,
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
                const LinearProgressIndicator(value: 0.33, backgroundColor: AppColors.borderLight, color: AppColors.secondaryGreen),
                const SizedBox(height: 24),
                const Text('Personal & Work Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 8),
                const Text('Provide your work details to register your agent account.', style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
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
                            icon: const Icon(Icons.my_location_rounded, color: AppColors.secondaryGreen),
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
                      child: const Text('Use Live OpenStreetMap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryGreenDark)),
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
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Continue to KYC'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
