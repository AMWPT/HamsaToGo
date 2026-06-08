import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/hamsa_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for auth state to resolve + minimum splash duration
    await Future.delayed(const Duration(milliseconds: 2400));

    if (!mounted) return;

    final auth = ref.read(authProvider);

    if (auth.isLoading) {
      // Auth still loading — wait a bit more
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (!mounted) return;

    final authFinal = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final hasLanguage = prefs.containsKey(StorageKeys.locale);

    if (!mounted) return;

    if (authFinal.isAdmin) {
      context.go(AppRoutes.adminDashboard);
    } else if (authFinal.user != null) {
      context.go(AppRoutes.home);
    } else if (!hasLanguage) {
      context.go(AppRoutes.language);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      body: Stack(
        children: [
          // Background radial gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.4,
                  colors: [
                    HamsaColors.greenBrand.withOpacity(0.35),
                    HamsaColors.bgDeep,
                  ],
                ),
              ),
            ),
          ),

          // Subtle noise overlay (placeholder for grain texture)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: HamsaColors.greenBrand.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                const HamsaLogo(size: 120)
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 28),

                // App name
                Text(
                  'HAMSA TO GO',
                  style: HamsaText.display(
                    size: 36,
                    letterSpacing: 6,
                    color: HamsaColors.cream,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                Text(
                  'COFFEE ROASTERS',
                  style: HamsaText.caption(
                    size: 11,
                    color: HamsaColors.creamMuted,
                    letterSpacing: 4,
                  ),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // Loading dot at bottom
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: _PulsingDot()
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 400.ms),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Logo ─────────────────────────────────────────────
class _ShimmerLogo extends StatelessWidget {
  final AnimationController controller;
  const _ShimmerLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                HamsaColors.cream,
                HamsaColors.gold,
                HamsaColors.cream,
                HamsaColors.goldLight,
                HamsaColors.cream,
              ],
              stops: [
                0.0,
                (controller.value - 0.2).clamp(0.0, 1.0),
                controller.value.clamp(0.0, 1.0),
                (controller.value + 0.2).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: const HamsaLogo(size: 120),
    );
  }
}

// ─── Pulsing Dot ─────────────────────────────────────────────
class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: HamsaColors.greenAccent,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 1, end: 1.8, duration: 700.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.8, end: 1, duration: 700.ms, curve: Curves.easeInOut);
  }
}
