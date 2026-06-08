import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/hamsa_button.dart';
import '../../widgets/hamsa_input.dart';
import '../../widgets/hamsa_logo.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_passCtrl.text.isEmpty) return;
    final success = await ref
        .read(authProvider.notifier)
        .loginAdmin(_passCtrl.text);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Incorrect password',
            style: HamsaText.body(size: 13),
          ),
          backgroundColor: HamsaColors.error.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      body: Stack(
        children: [
          // Dark vignette background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    HamsaColors.greenBrand.withOpacity(0.15),
                    HamsaColors.bgDeep,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Back
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: HamsaColors.muted),
                          const SizedBox(width: 4),
                          Text('Back',
                              style: HamsaText.body(
                                  size: 13, color: HamsaColors.muted)),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Lock icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: HamsaColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HamsaColors.borderStrong),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: HamsaColors.cream,
                        size: 32,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 24),

                  Text(
                    'Staff Access',
                    style: HamsaText.display(
                        size: 34, color: HamsaColors.cream),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 6),

                  Text(
                    'This device is authorized for staff only',
                    style: HamsaText.body(
                        size: 13, color: HamsaColors.muted),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 48),

                  HamsaInput(
                    label: 'Staff Password',
                    controller: _passCtrl,
                    obscure: true,
                    prefixIcon: Icons.vpn_key_outlined,
                    autofocus: true,
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  HamsaButton(
                    label: 'Access Dashboard',
                    onTap: auth.isLoading ? null : _login,
                    isLoading: auth.isLoading,
                    style: HamsaButtonStyle.gold,
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 400.ms),

                  const Spacer(flex: 2),

                  // Hamsa branding
                  const HamsaLogo(size: 32)
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 12),

                  Text(
                    'Hamsa Coffee Roasters',
                    style: HamsaText.caption(
                        size: 11, color: HamsaColors.subtle),
                  )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
