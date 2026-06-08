import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/hamsa_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  String? _verificationId;
  bool _step2    = false;
  bool _sending  = false;
  bool _verifying = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final raw = _phoneCtrl.text.trim();
    if (raw.startsWith('+')) return raw;
    final digits = raw.startsWith('0') ? raw.substring(1) : raw;
    return '+966$digits';
  }

  // ── Send OTP ─────────────────────────────────────────────────
  Future<void> _sendCode() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) { _showError('Please enter your full name'); return; }

    final phone = _fullPhone;
    if (phone.length < 10) { _showError('Please enter a valid phone number'); return; }

    setState(() => _sending = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _sending = false);
        _showError(e.message ?? 'Failed to send code');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _sending = false;
          _step2 = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ── Verify OTP ───────────────────────────────────────────────
  Future<void> _verifyCode() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) { _showError('Enter the 6-digit code'); return; }
    if (_verificationId == null) return;

    setState(() => _verifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _verifying = false);
      _showError(e.message ?? 'Invalid code');
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user!.getIdToken();

      await ref.read(authProvider.notifier).completePhoneAuth(
            idToken: idToken!,
            fullName: _nameCtrl.text.trim(),
          );

      if (!mounted) return;
      final error = ref.read(authProvider).error;
      if (error != null) {
        setState(() => _verifying = false);
        _showError(error);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _verifying = false);
      _showError(e.message ?? 'Verification failed');
    } catch (e) {
      setState(() => _verifying = false);
      _showError('Something went wrong. Try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: HamsaText.body(size: 14, color: HamsaColors.bgDeep)),
      backgroundColor: HamsaColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final isBusy = _sending || _verifying;

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: HamsaColors.muted, size: 20),
          onPressed: () {
            if (_step2) {
              setState(() { _step2 = false; _otpCtrl.clear(); });
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Text(
              isAr ? 'إنشاء حساب' : 'Create Account',
              style: HamsaText.display(size: 38, color: HamsaColors.cream),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.15, end: 0),

            const SizedBox(height: 8),

            Text(
              isAr ? 'انضم إلى مجتمع حمصة' : 'Join the Hamsa community',
              style: HamsaText.body(size: 15, color: HamsaColors.creamMuted),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 40),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _step2
                  ? _Step2(
                      key: const ValueKey('otp'),
                      isAr: isAr,
                      phone: _fullPhone,
                      otpCtrl: _otpCtrl,
                      isBusy: isBusy,
                      onVerify: _verifyCode,
                    )
                  : _Step1(
                      key: const ValueKey('form'),
                      isAr: isAr,
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      isBusy: isBusy,
                      onSend: _sendCode,
                    ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAr ? 'لديك حساب؟ ' : 'Already have an account? ',
                  style: HamsaText.body(size: 13, color: HamsaColors.muted),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: Text(
                    isAr ? 'تسجيل الدخول' : 'Sign In',
                    style: HamsaText.body(size: 13, color: HamsaColors.greenAccent, weight: FontWeight.w600),
                  ),
                ),
              ],
            ).animate(delay: 400.ms).fadeIn(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Name + Phone ─────────────────────────────────────
class _Step1 extends StatelessWidget {
  final bool isAr;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool isBusy;
  final VoidCallback onSend;

  const _Step1({
    super.key,
    required this.isAr,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.isBusy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Name field
        _LabeledField(
          label: isAr ? 'الاسم الكامل' : 'Full Name',
          child: TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: HamsaText.body(size: 16, color: HamsaColors.cream),
            decoration: _inputDeco(isAr ? 'مثال: أحمد محمد' : 'e.g. Ahmed Mohammed'),
          ),
        ),
        const SizedBox(height: 16),

        // Phone field
        _LabeledField(
          label: isAr ? 'رقم الجوال' : 'Phone Number',
          child: _PhoneField(controller: phoneCtrl, isAr: isAr),
        ),
        const SizedBox(height: 32),

        HamsaButton(
          label: isAr ? 'إرسال رمز التحقق' : 'Send Verification Code',
          onTap: isBusy ? null : onSend,
          isLoading: isBusy,
        ),
      ],
    );
  }
}

// ── Step 2: OTP ───────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final bool isAr;
  final String phone;
  final TextEditingController otpCtrl;
  final bool isBusy;
  final VoidCallback onVerify;

  const _Step2({
    super.key,
    required this.isAr,
    required this.phone,
    required this.otpCtrl,
    required this.isBusy,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr
              ? 'تم إرسال رمز مكون من 6 أرقام إلى $phone'
              : 'A 6-digit code was sent to $phone',
          style: HamsaText.body(size: 14, color: HamsaColors.creamMuted),
        ),
        const SizedBox(height: 24),

        _LabeledField(
          label: isAr ? 'رمز التحقق' : 'Verification Code',
          child: _OtpField(controller: otpCtrl, onSubmit: onVerify),
        ),
        const SizedBox(height: 32),

        HamsaButton(
          label: isAr ? 'إنشاء الحساب' : 'Create Account',
          onTap: isBusy ? null : onVerify,
          isLoading: isBusy,
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
InputDecoration _inputDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: HamsaText.body(size: 14, color: HamsaColors.subtle),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HamsaText.body(size: 13, color: HamsaColors.muted, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: HamsaColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HamsaColors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final bool isAr;
  const _PhoneField({required this.controller, required this.isAr});

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: HamsaColors.inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? HamsaColors.greenAccent.withOpacity(0.8) : HamsaColors.border,
            width: _focused ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: HamsaColors.border)),
              ),
              child: Text('+966',
                  style: HamsaText.body(size: 15, color: HamsaColors.cream, weight: FontWeight.w600)),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: HamsaText.body(size: 16, color: HamsaColors.cream),
                decoration: InputDecoration(
                  hintText: '5XX XXX XXXX',
                  hintStyle: HamsaText.body(size: 15, color: HamsaColors.subtle),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _OtpField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      style: HamsaText.body(size: 28, color: HamsaColors.cream, weight: FontWeight.w700, letterSpacing: 8),
      decoration: const InputDecoration(
        hintText: '------',
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      onSubmitted: (_) => onSubmit(),
    );
  }
}
