import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_spring_button.dart';
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
    if (_isLoading) return;
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP'), backgroundColor: AppColors.statusError),
      );
      return;
    }

    setState(() => _isLoading = true);
    final mobileNumber = ref.read(authProvider).mobileNumber ?? '';
    final success = await ref.read(authProvider.notifier).verifyOtp(mobileNumber, _otpController.text.trim());
    
    if (mounted) {
      setState(() => _isLoading = false);
    }

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
      body: Stack(
        children: [
          // 1. Clean Luxury Architectural Villa Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.network(
                'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1600&auto=format&fit=crop&q=85',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Soft Daylight Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.90),
                    Colors.white.withOpacity(0.55),
                    Colors.white.withOpacity(0.92),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar: Back Button & Centered Logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827), size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/app_logo.png',
                          height: 55,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Headline: Verification Code (Clean, Modern Typography)
                    Text(
                      'Verification Code',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Subtitle with Mobile Number
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          color: const Color(0xFF4B5563),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                          TextSpan(
                            text: '+91 $mobileNumber',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 4. Frosted Card Container (Clean, Minimalist)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.90),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
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
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                textStyle: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.box,
                                  borderRadius: BorderRadius.circular(10),
                                  fieldHeight: 48,
                                  fieldWidth: 38,
                                  activeColor: const Color(0xFF047857),
                                  selectedColor: const Color(0xFF047857),
                                  inactiveColor: const Color(0xFFD1D5DB),
                                  activeFillColor: Colors.white,
                                  selectedFillColor: Colors.white,
                                  inactiveFillColor: const Color(0xFFF9FAFB),
                                  borderWidth: 1.5,
                                ),
                                enableActiveFill: true,
                                onChanged: (val) {},
                                onCompleted: (val) {
                                  _handleVerify();
                                },
                              ),
                              const SizedBox(height: 22),

                              // Deep Emerald Animated Spring Button
                              AnimatedSpringButton(
                                text: 'Verify & Continue',
                                onPressed: _isLoading ? null : _handleVerify,
                                isLoading: _isLoading,
                                height: 50,
                                borderRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Resend Timer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _cooldownSeconds > 0 ? 'Resend code in ${_cooldownSeconds}s' : "Didn't receive the code? ",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (_cooldownSeconds == 0)
                          TextButton(
                            onPressed: () {
                              ref.read(authProvider.notifier).sendOtp(mobileNumber);
                              _startTimer();
                              _listenForOtpSms();
                            },
                            child: Text(
                              'Resend OTP',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF047857),
                                fontSize: 13.5,
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
        ],
      ),
    );
  }
}
