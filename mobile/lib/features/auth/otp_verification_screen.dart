import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> with CodeAutoFill {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _cooldownSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenForOtpSms();
  }

  void _listenForOtpSms() async {
    try {
      await SmsAutoFill().listenForCode();
    } catch (_) {}
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      setState(() {
        _otpController.text = code!;
      });
      _handleVerify();
    }
  }

  void _startTimer() {
    _cooldownSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  @override
  void dispose() {
    cancel();
    SmsAutoFill().unregisterListener();
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP'), backgroundColor: AppColors.statusError),
      );
      return;
    }

    setState(() => _isLoading = true);
    final mobileNumber = ref.read(authProvider).mobileNumber ?? '';
    final success = await ref.read(authProvider.notifier).verifyOtp(mobileNumber, _otpController.text.trim());
    setState(() => _isLoading = false);

    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage ?? 'Verification failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.statusError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobileNumber = ref.watch(authProvider).mobileNumber ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded, size: 54, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verification Code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We have sent a 6-digit OTP code to +91 $mobileNumber',
                style: const TextStyle(fontSize: 14, color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // OTP Pin Input with SMS AutoFill & Auto-Submit on Completion
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                enablePinAutofill: true,
                autoFocus: true,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeColor: AppColors.primaryNavy,
                  selectedColor: AppColors.secondaryGreen,
                  inactiveColor: AppColors.borderLight,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: AppColors.inputFill,
                ),
                enableActiveFill: true,
                onChanged: (val) {},
                onCompleted: (val) {
                  // Instant auto-submit as soon as 6 digits are autofilled or typed!
                  _handleVerify();
                },
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phonelink_ring_rounded, size: 14, color: AppColors.secondaryGreen),
                  SizedBox(width: 6),
                  Text('SMS AutoFill Active — OTP will auto-read & submit', style: TextStyle(fontSize: 12, color: AppColors.secondaryGreenDark, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Verify & Proceed'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _cooldownSeconds > 0 ? 'Resend code in ${_cooldownSeconds}s' : "Didn't receive OTP? ",
                    style: const TextStyle(color: AppColors.textMedium),
                  ),
                  if (_cooldownSeconds == 0)
                    TextButton(
                      onPressed: () {
                        ref.read(authProvider.notifier).sendOtp(mobileNumber);
                        _startTimer();
                        _listenForOtpSms();
                      },
                      child: const Text('Resend OTP', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
