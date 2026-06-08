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
import '../../widgets/hamsa_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
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
      body: Stack(
        children: [
          // Top hero gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HamsaColors.greenBrand.withOpacity(0.5),
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

                  // Logo
                  const HamsaLogo(size: 100)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: Offset(0.8, 0.8)),

                  const SizedBox(height: 16),

                  Text(
                    'HAMSA TO GO',
                    style: HamsaText.display(
                      size: 30,
                      letterSpacing: 5,
                      color: HamsaColors.cream,
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 4),

                  Text(
                    isAr ? 'أهلاً بك' : 'Welcome back',
                    style: isAr
                        ? HamsaText.arabic(
                            size: 14,
                            color: HamsaColors.creamMuted,
                          )
                        : HamsaText.body(
                            size: 14,
                            color: HamsaColors.creamMuted,
                          ),
                  )
                      .animate(delay: 250.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 48),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: HamsaColors.bgCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: HamsaColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'تسجيل الدخول' : 'Sign In',
                            style: HamsaText.heading(
                                size: 22, color: HamsaColors.cream),
                          ),
                          const SizedBox(height: 24),

                          HamsaInput(
                            label: isAr ? 'البريد الإلكتروني' : 'Email',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) => v != null && v.contains('@')
                                ? null
                                : (isAr
                                    ? 'البريد غير صالح'
                                    : 'Invalid email'),
                          ),

                          const SizedBox(height: 16),

                          HamsaInput(
                            label: isAr ? 'كلمة المرور' : 'Password',
                            controller: _passCtrl,
                            obscure: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (v) =>
                                v != null && v.length >= 6
                                    ? null
                                    : (isAr
                                        ? 'كلمة المرور قصيرة جداً'
                                        : 'Too short'),
                          ),

                          const SizedBox(height: 28),

                          HamsaButton(
                            label: isAr ? 'دخول' : 'Sign In',
                            onTap: auth.isLoading ? null : _login,
                            isLoading: auth.isLoading,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'ليس لديك حساب؟ ' : "Don't have an account? ",
                        style: HamsaText.body(
                            size: 13, color: HamsaColors.muted),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.register),
                        child: Text(
                          isAr ? 'إنشاء حساب' : 'Create one',
                          style: HamsaText.body(
                            size: 13,
                            color: HamsaColors.greenAccent,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 12),

                  // Admin link
                  TextButton(
                    onPressed: () => context.go(AppRoutes.adminLogin),
                    child: Text(
                      isAr ? 'دخول الموظفين' : 'Staff Login',
                      style: HamsaText.body(
                          size: 12, color: HamsaColors.subtle),
                    ),
                  )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
