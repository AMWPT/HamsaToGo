import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_errors.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/hamsa_button.dart';
import '../../widgets/hamsa_logo.dart';
import '../../widgets/lang_toggle_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ── Step 1: phone entry ──────────────────────────────────────
  final _phoneCtrl = TextEditingController();

  // ── Step 2: OTP entry ────────────────────────────────────────
  final _otpCtrl = TextEditingController();
  String? _verificationId;

  bool _step2 = false;       // true = showing OTP field
  bool _sending = false;     // waiting for SMS
  bool _verifying = false;   // waiting for backend

  bool get _isAr => ref.read(localeProvider).languageCode == 'ar';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final raw = _phoneCtrl.text.trim();
    // Already starts with + → use as-is
    if (raw.startsWith('+')) return raw;
    // Saudi default: prepend +966, drop leading 0
    final digits = raw.startsWith('0') ? raw.substring(1) : raw;
    return '+966$digits';
  }

  // ── Send OTP ─────────────────────────────────────────────────
  Future<void> _sendCode() async {
    final phone = _fullPhone;
    if (phone.length < 10) {
      _showError(_isAr
          ? 'الرجاء إدخال رقم جوال صحيح'
          : 'Please enter a valid phone number');
      return;
    }

    setState(() => _sending = true);

    // Check the account exists BEFORE sending an OTP — otherwise an SMS
    // is wasted (and rate limit burned) just to learn there's no account.
    try {
      final exists = await ref.read(apiServiceProvider).phoneExists(phone);
      if (!exists) {
        setState(() => _sending = false);
        _showError(
          _isAr
              ? 'لا يوجد حساب بهذا الرقم. الرجاء إنشاء حساب أولاً.'
              : 'No account found. Please register first.',
          action: SnackBarAction(
            label: _isAr ? 'إنشاء حساب' : 'Register',
            textColor: HamsaColors.bgDeep,
            onPressed: () => context.go(AppRoutes.register),
          ),
        );
        return;
      }
    } catch (_) {
      // Backend unreachable — fall through and let the normal OTP flow
      // proceed; the post-verify check still catches missing accounts.
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-retrieval
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _sending = false);
        _showError(friendlyAuthError(
          e,
          isAr: _isAr,
          fallbackEn: 'Could not send the code. Please try again.',
          fallbackAr: 'تعذّر إرسال الرمز. حاول مرة أخرى.',
        ));
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
    if (code.length != 6) {
      _showError(_isAr
          ? 'أدخل الرمز المكوّن من 6 أرقام'
          : 'Enter the 6-digit code');
      return;
    }
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
      _showError(friendlyAuthError(
        e,
        isAr: _isAr,
        fallbackEn: 'Could not verify the code. Please try again.',
        fallbackAr: 'تعذّر التحقق من الرمز. حاول مرة أخرى.',
      ));
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user!.getIdToken();

      await ref.read(authProvider.notifier).completePhoneAuth(
            idToken: idToken!,
          );

      if (!mounted) return;
      final error = ref.read(authProvider).error;
      if (error != null) {
        setState(() => _verifying = false);
        if (error == 'NO_ACCOUNT') {
          // The OTP is already verified and the Firebase session is live —
          // don't send the user to the register screen (which would burn a
          // SECOND SMS for the same phone). Just ask for their name and
          // finish creating the account with the session we already have.
          await _promptNameAndRegister();
        } else {
          _showError(_isAr
              ? 'تعذّر الاتصال بالخادم. حاول مرة أخرى.'
              : 'Could not connect to server. Please try again.');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _verifying = false);
      _showError(friendlyAuthError(
        e,
        isAr: _isAr,
        fallbackEn: 'Sign-in failed. Please try again.',
        fallbackAr: 'تعذّر تسجيل الدخول. حاول مرة أخرى.',
      ));
    } catch (e) {
      setState(() => _verifying = false);
      _showError(_isAr
          ? 'حدث خطأ. حاول مجدداً.'
          : 'Something went wrong. Try again.');
    }
  }

  /// OTP verified but no account exists — collect a name and finish
  /// registration with the already-verified Firebase session, so no
  /// second OTP/SMS is ever needed.
  Future<void> _promptNameAndRegister() async {
    final isAr = _isAr;
    final nameCtrl = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: HamsaColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'أكمل إنشاء حسابك' : 'Complete your account',
          style: HamsaText.heading(size: 20),
          textAlign: isAr ? TextAlign.right : TextAlign.left,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'تم التحقق من رقمك بنجاح. أدخل اسمك لإكمال التسجيل.'
                  : 'Your number is verified. Enter your name to finish registering.',
              style: HamsaText.body(size: 13, color: HamsaColors.muted),
              textAlign: isAr ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              style: isAr
                  ? HamsaText.arabic(size: 15, color: HamsaColors.cream)
                  : HamsaText.body(size: 15, color: HamsaColors.cream),
              decoration: InputDecoration(
                hintText: isAr ? 'الاسم الكامل' : 'Full name',
                hintStyle: HamsaText.body(size: 14, color: HamsaColors.subtle),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: HamsaText.body(size: 14, color: HamsaColors.muted),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(nameCtrl.text.trim()),
            child: Text(
              isAr ? 'إنشاء الحساب' : 'Create account',
              style: HamsaText.body(
                size: 14,
                weight: FontWeight.w700,
                color: HamsaColors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return; // user cancelled

    setState(() => _verifying = true);
    try {
      // Reuse the live Firebase session — a fresh token, no new OTP.
      final idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) throw Exception('Session expired');

      await ref
          .read(authProvider.notifier)
          .completePhoneAuth(idToken: idToken, fullName: name);

      if (!mounted) return;
      final error = ref.read(authProvider).error;
      if (error != null) {
        setState(() => _verifying = false);
        _showError(_isAr
            ? 'تعذّر إنشاء الحساب. حاول مرة أخرى.'
            : 'Could not create the account. Please try again.');
      }
      // On success the router redirects to home automatically.
    } catch (_) {
      if (!mounted) return;
      setState(() => _verifying = false);
      _showError(_isAr
          ? 'حدث خطأ. حاول مجدداً.'
          : 'Something went wrong. Try again.');
    }
  }

  void _showError(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: HamsaText.body(size: 14, color: HamsaColors.bgDeep)),
      backgroundColor: HamsaColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: action,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final isBusy = _sending || _verifying;

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      body: Stack(
        children: [
          // Top gradient
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HamsaColors.greenBrand.withValues(alpha: 0.5),
                    HamsaColors.bgDeep,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  const HamsaLogo(size: 100)
                      .animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 16),

                  Text('HAMSA TO GO',
                      style: HamsaText.display(size: 30, letterSpacing: 5, color: HamsaColors.cream))
                      .animate(delay: 150.ms).fadeIn(),

                  const SizedBox(height: 4),

                  Text(
                    isAr ? 'أهلاً بك' : 'Welcome back',
                    style: isAr
                        ? HamsaText.arabic(size: 14, color: HamsaColors.creamMuted)
                        : HamsaText.body(size: 14, color: HamsaColors.creamMuted),
                  ).animate(delay: 250.ms).fadeIn(),

                  const SizedBox(height: 48),

                  // ── Card ────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _step2
                        ? _OtpCard(
                            key: const ValueKey('otp'),
                            isAr: isAr,
                            phone: _fullPhone,
                            otpCtrl: _otpCtrl,
                            isBusy: isBusy,
                            onVerify: _verifyCode,
                            onBack: () => setState(() {
                              _step2 = false;
                              _otpCtrl.clear();
                            }),
                          )
                        : _PhoneCard(
                            key: const ValueKey('phone'),
                            isAr: isAr,
                            phoneCtrl: _phoneCtrl,
                            isBusy: isBusy,
                            onSend: _sendCode,
                          ),
                  ).animate(delay: 350.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'ليس لديك حساب؟ ' : "Don't have an account? ",
                        style: HamsaText.body(size: 13, color: HamsaColors.muted),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.register),
                        child: Text(
                          isAr ? 'إنشاء حساب' : 'Create one',
                          style: HamsaText.body(size: 13, color: HamsaColors.greenAccent, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ).animate(delay: 500.ms).fadeIn(),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => context.go(AppRoutes.adminLogin),
                    child: Text(
                      isAr ? 'دخول الموظفين' : 'Staff Login',
                      style: HamsaText.body(size: 12, color: HamsaColors.subtle),
                    ),
                  ).animate(delay: 600.ms).fadeIn(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Language toggle — last so it sits on top
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 12, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: LangToggleButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phone entry card ─────────────────────────────────────────
class _PhoneCard extends StatelessWidget {
  final bool isAr;
  final TextEditingController phoneCtrl;
  final bool isBusy;
  final VoidCallback onSend;

  const _PhoneCard({
    super.key,
    required this.isAr,
    required this.phoneCtrl,
    required this.isBusy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: HamsaColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HamsaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'تسجيل الدخول' : 'Sign In',
            style: HamsaText.heading(size: 22, color: HamsaColors.cream),
          ),
          const SizedBox(height: 6),
          Text(
            isAr ? 'أدخل رقم جوالك' : 'Enter your phone number',
            style: HamsaText.body(size: 13, color: HamsaColors.muted),
          ),
          const SizedBox(height: 24),

          // Phone field with +966 prefix
          _PhoneField(controller: phoneCtrl, isAr: isAr),

          const SizedBox(height: 28),

          HamsaButton(
            label: isAr ? 'إرسال الرمز' : 'Send Code',
            onTap: isBusy ? null : onSend,
            isLoading: isBusy,
          ),
        ],
      ),
    );
  }
}

// ── OTP entry card ───────────────────────────────────────────
class _OtpCard extends StatelessWidget {
  final bool isAr;
  final String phone;
  final TextEditingController otpCtrl;
  final bool isBusy;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  const _OtpCard({
    super.key,
    required this.isAr,
    required this.phone,
    required this.otpCtrl,
    required this.isBusy,
    required this.onVerify,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: HamsaColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HamsaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: HamsaColors.muted, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                isAr ? 'أدخل الرمز' : 'Enter Code',
                style: HamsaText.heading(size: 22, color: HamsaColors.cream),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'تم إرسال رمز مكون من 6 أرقام إلى $phone'
                : 'A 6-digit code was sent to $phone',
            style: HamsaText.body(size: 13, color: HamsaColors.muted),
          ),
          const SizedBox(height: 28),

          _OtpField(controller: otpCtrl, onSubmit: onVerify),

          const SizedBox(height: 28),

          HamsaButton(
            label: isAr ? 'تحقق' : 'Verify',
            onTap: isBusy ? null : onVerify,
            isLoading: isBusy,
          ),
        ],
      ),
    );
  }
}

// ── Shared phone input with +966 prefix ──────────────────────
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
            color: _focused ? HamsaColors.greenAccent.withValues(alpha: 0.8) : HamsaColors.border,
            width: _focused ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Country code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: HamsaColors.border),
                ),
              ),
              child: Text('+966',
                  style: HamsaText.body(size: 15, color: HamsaColors.cream, weight: FontWeight.w600)),
            ),
            // Number
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: HamsaText.body(size: 16, color: HamsaColors.cream),
                decoration: InputDecoration(
                  hintText: widget.isAr ? '5XX XXX XXXX' : '5XX XXX XXXX',
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

// ── OTP input field ──────────────────────────────────────────
class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _OtpField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HamsaColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HamsaColors.border),
      ),
      child: TextField(
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
      ),
    );
  }
}
