import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/hamsa_button.dart';
import '../../widgets/hamsa_input.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
        );
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: HamsaText.body(size: 13)),
          backgroundColor: HamsaColors.error.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: HamsaColors.muted, size: 20),
          onPressed: () => context.go(AppRoutes.login),
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
              style: HamsaText.display(
                  size: 38, color: HamsaColors.cream),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.15, end: 0),

            const SizedBox(height: 8),

            Text(
              isAr
                  ? 'انضم إلى مجتمع حمصة'
                  : 'Join the Hamsa community',
              style: HamsaText.body(
                  size: 15, color: HamsaColors.creamMuted),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 40),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  HamsaInput(
                    label: isAr ? 'الاسم الكامل' : 'Full Name',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) => v != null && v.trim().length >= 2
                        ? null
                        : (isAr ? 'الاسم مطلوب' : 'Name is required'),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  HamsaInput(
                    label: isAr ? 'البريد الإلكتروني' : 'Email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : (isAr ? 'بريد غير صالح' : 'Invalid email'),
                  )
                      .animate(delay: 280.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  HamsaInput(
                    label: isAr ? 'كلمة المرور' : 'Password',
                    controller: _passCtrl,
                    obscure: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => v != null && v.length >= 6
                        ? null
                        : (isAr ? 'على الأقل 6 أحرف' : 'Min 6 characters'),
                  )
                      .animate(delay: 360.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  HamsaInput(
                    label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
                    controller: _confirmCtrl,
                    obscure: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => v == _passCtrl.text
                        ? null
                        : (isAr
                            ? 'كلمات المرور غير متطابقة'
                            : "Passwords don't match"),
                  )
                      .animate(delay: 440.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 36),

                  HamsaButton(
                    label: isAr ? 'إنشاء الحساب' : 'Create Account',
                    onTap: auth.isLoading ? null : _register,
                    isLoading: auth.isLoading,
                  )
                      .animate(delay: 520.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ',
                        style: HamsaText.body(
                            size: 13, color: HamsaColors.muted),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text(
                          isAr ? 'تسجيل الدخول' : 'Sign In',
                          style: HamsaText.body(
                            size: 13,
                            color: HamsaColors.greenAccent,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 580.ms)
                      .fadeIn(duration: 400.ms),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
