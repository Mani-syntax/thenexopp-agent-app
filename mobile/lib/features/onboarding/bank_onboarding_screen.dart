import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/providers/dio_provider.dart';
import '../../shared/providers/auth_provider.dart';

class BankOnboardingScreen extends ConsumerStatefulWidget {
  const BankOnboardingScreen({super.key});

  @override
  ConsumerState<BankOnboardingScreen> createState() => _BankOnboardingScreenState();
}

class _BankOnboardingScreenState extends ConsumerState<BankOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();
  final _phonepeController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitBankDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountController.text.trim() != _confirmAccountController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account numbers do not match'), backgroundColor: AppColors.statusError),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.post(ApiConstants.submitBankDetails, data: {
        'accountNumber': _accountController.text.trim(),
        'confirmAccountNumber': _confirmAccountController.text.trim(),
        'ifscCode': _ifscController.text.trim().toUpperCase(),
        'upiId': _upiController.text.trim(),
        'phonepeNumber': _phonepeController.text.trim(),
      });

      if (response.data['success'] == true && mounted) {
        ref.read(authProvider.notifier).updateAgentState('PENDING_APPROVAL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit bank details'), backgroundColor: AppColors.statusError),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank & Payout (Step 3 of 3)')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(value: 1.0, backgroundColor: AppColors.borderLight, color: AppColors.secondaryGreen),
                const SizedBox(height: 24),
                const Text('Banking & Payout Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 8),
                const Text('Earnings will be transferred directly to this bank account or UPI ID.', style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Bank Account Number', prefixIcon: Icon(Icons.account_balance_rounded)),
                  validator: (val) => val == null || val.trim().length < 9 ? 'Enter valid account number' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmAccountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Confirm Bank Account Number', prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Confirm account number' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ifscController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'IFSC Code (e.g. SBIN0001234)', prefixIcon: Icon(Icons.location_city_rounded)),
                  validator: (val) => val == null || val.trim().length != 11 ? 'Enter 11-char IFSC Code' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(labelText: 'Primary UPI ID (e.g. agent@upi)', prefixIcon: Icon(Icons.qr_code_rounded)),
                  validator: (val) => val == null || !val.contains('@') ? 'Enter valid UPI ID' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phonepeController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'PhonePe / Paytm Number (Optional)', prefixIcon: Icon(Icons.phone_iphone_rounded)),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitBankDetails,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Registration & Submit for Review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
