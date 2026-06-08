import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/hamsa_logo.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HamsaColors.greenBrand.withOpacity(0.2),
                    HamsaColors.bgDeep,
                    HamsaColors.bgDeep,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Logo
                  const HamsaLogo(size: 100)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: Offset(0.85, 0.85)),

                  const SizedBox(height: 20),

                  Text(
                    'HAMSA TO GO',
                    style: HamsaText.display(
                      size: 24,
                      letterSpacing: 5,
                      color: HamsaColors.creamMuted,
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms),

                  const Spacer(),

                  // Choose language heading
                  Column(
                    children: [
                      Text(
                        'Choose your language',
                        style: HamsaText.heading(size: 22, color: HamsaColors.cream),
                        textAlign: TextAlign.center,
                      )
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        'اختر لغتك',
                        style: HamsaText.arabic(size: 22, color: HamsaColors.creamMuted),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      )
                          .animate(delay: 500.ms)
                          .fadeIn(duration: 400.ms),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Language cards — side by side
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageCard(
                          lang: 'en',
                          label: 'English',
                          subLabel: 'Continue in English',
                          flag: '🇬🇧',
                          delay: 600,
                          onTap: () => _select(context, ref, 'en'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LanguageCard(
                          lang: 'ar',
                          label: 'العربية',
                          subLabel: 'تابع بالعربية',
                          flag: '🇸🇦',
                          delay: 700,
                          isRtl: true,
                          onTap: () => _select(context, ref, 'ar'),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Admin link
                  TextButton(
                    onPressed: () => context.go(AppRoutes.adminLogin),
                    child: Text(
                      'Staff Login',
                      style: HamsaText.body(
                        size: 12,
                        color: HamsaColors.muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                  )
                      .animate(delay: 900.ms)
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

  void _select(BuildContext context, WidgetRef ref, String lang) {
    ref.read(localeProvider.notifier).setLocale(lang);
    context.go(AppRoutes.login);
  }
}

class _LanguageCard extends StatefulWidget {
  final String lang;
  final String label;
  final String subLabel;
  final String flag;
  final int delay;
  final bool isRtl;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.lang,
    required this.label,
    required this.subLabel,
    required this.flag,
    required this.delay,
    required this.onTap,
    this.isRtl = false,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: HamsaColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: HamsaColors.borderStrong,
              width: 1,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF163524),
                Color(0xFF0F2B1A),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: widget.isRtl
                    ? HamsaText.arabic(
                        size: 22,
                        weight: FontWeight.w700,
                        color: HamsaColors.cream,
                      )
                    : HamsaText.heading(size: 20, color: HamsaColors.cream),
                textDirection:
                    widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
              const SizedBox(height: 6),
              Text(
                widget.subLabel,
                style: HamsaText.body(size: 12, color: HamsaColors.muted),
                textDirection:
                    widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic);
  }
}
