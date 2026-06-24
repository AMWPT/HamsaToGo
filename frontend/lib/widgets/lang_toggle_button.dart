import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/locale_provider.dart';

/// Reusable AR/EN language toggle button.
/// Drop into any AppBar's actions or as a Positioned overlay.
class LangToggleButton extends ConsumerWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return GestureDetector(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(isAr ? 'en' : 'ar');
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HamsaColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          isAr ? 'EN' : 'ع',
          style: HamsaText.body(
            size: 13,
            weight: FontWeight.w700,
            color: HamsaColors.gold,
          ),
        ),
      ),
    );
  }
}
