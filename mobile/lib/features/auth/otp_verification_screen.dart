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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verify Mobile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon Header with subtle emerald badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.emeraldBorder, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      size: 48,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit verification code to\n+91 $mobileNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMedium,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // White Card Pin Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        enablePinAutofill: true,
                        autoFocus: true,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(14),
                          fieldHeight: 56,
                          fieldWidth: 44,
                          activeColor: AppColors.primaryEmerald,
                          selectedColor: AppColors.primaryEmerald,
                          inactiveColor: AppColors.borderLight,
                          activeFillColor: Colors.white,
                          selectedFillColor: AppColors.emeraldSurface,
                          inactiveFillColor: AppColors.inputFillSubtle,
                          borderWidth: 1.5,
                        ),
                        enableActiveFill: true,
                        onChanged: (val) {},
                        onCompleted: (val) {
                          _handleVerify();
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.emeraldBorder),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.primaryEmerald),
                            SizedBox(width: 6),
                            Text(
                              'SMS AutoFill Active — will auto-submit',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryEmeraldDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: AppColors.primaryEmerald.withAlpha(100),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _cooldownSeconds > 0 ? 'Resend code in ${_cooldownSeconds}s' : "Didn't get the code? ",
                      style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                    ),
                    if (_cooldownSeconds == 0)
                      TextButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).sendOtp(mobileNumber);
                          _startTimer();
                          _listenForOtpSms();
                        },
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryEmerald,
                            fontSize: 13,
                          ),
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
