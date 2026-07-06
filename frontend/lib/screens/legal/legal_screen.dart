import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/legal_content.dart';
import '../../providers/locale_provider.dart';

class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({super.key});

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      appBar: AppBar(
        backgroundColor: HamsaColors.bgDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: HamsaColors.muted, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'السياسات والشروط' : 'Policies & Terms',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: HamsaColors.greenAccent,
          labelColor: HamsaColors.cream,
          unselectedLabelColor: HamsaColors.muted,
          labelStyle: HamsaText.body(size: 12, weight: FontWeight.w600),
          tabs: [
            Tab(text: isAr ? 'الشروط والأحكام' : 'Terms'),
            Tab(text: isAr ? 'الخصوصية' : 'Privacy'),
            Tab(text: isAr ? 'الاسترجاع' : 'Refunds'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LegalBody(text: isAr ? LegalContent.termsAr : LegalContent.termsEn, isAr: isAr),
          _LegalBody(text: isAr ? LegalContent.privacyAr : LegalContent.privacyEn, isAr: isAr),
          _LegalBody(text: isAr ? LegalContent.refundAr : LegalContent.refundEn, isAr: isAr),
        ],
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  final String text;
  final bool isAr;
  const _LegalBody({required this.text, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        text.trim(),
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        style: isAr
            ? HamsaText.arabic(size: 14, color: HamsaColors.offWhite, height: 1.9)
            : HamsaText.body(size: 14, color: HamsaColors.offWhite, height: 1.7),
      ),
    );
  }
}
