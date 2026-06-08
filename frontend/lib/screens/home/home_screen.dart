import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/menu_item.dart';
import '../../widgets/menu_item_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final collapsed = _scrollController.offset > 60;
      if (collapsed != _collapsed) {
        setState(() => _collapsed = collapsed);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final isAr = locale == 'ar';
    final selectedCat = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(menuItemsProvider(selectedCat));
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  collapsed: _collapsed,
                  userName: auth.user?.fullName ?? '',
                  isAr: isAr,
                  onOrdersTap: () => context.push(AppRoutes.myOrders),
                  onToggleLocale: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(isAr ? 'en' : 'ar'),
                  onSignOut: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                ),
              ),

              // ── Category Chips ───────────────────────────────
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (cats) => _CategoryRow(
                    categories: cats,
                    selected: selectedCat,
                    locale: locale,
                    onSelect: (id) => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = id,
                  ),
                  loading: () => const SizedBox(height: 60),
                  error: (_, __) => const SizedBox(height: 60),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Menu Items ───────────────────────────────────
              itemsAsync.when(
                data: (items) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => MenuItemCard(
                        item: items[i],
                        locale: locale,
                        index: i,
                      ).animate(delay: Duration(milliseconds: i * 60))
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.25, end: 0),
                      childCount: items.length,
                    ),
                  ),
                ),
                loading: () => SliverToBoxAdapter(
                  child: Column(
                    children: List.generate(
                      4,
                      (i) => _SkeletonCard()
                          .animate(delay: Duration(milliseconds: i * 80))
                          .shimmer(duration: 1200.ms),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        isAr
                            ? 'تعذر تحميل القائمة'
                            : 'Failed to load menu',
                        style: HamsaText.body(color: HamsaColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Floating Cart Button ─────────────────────────────
          if (cartCount > 0)
            Positioned(
              bottom: 32,
              left: 28,
              right: 28,
              child: _CartFAB(count: cartCount, isAr: isAr),
            ),
        ],
      ),
    );
  }
}

// ─── Header Delegate ─────────────────────────────────────────
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool collapsed;
  final String userName;
  final bool isAr;
  final VoidCallback onOrdersTap;
  final VoidCallback onToggleLocale;
  final VoidCallback onSignOut;

  const _HomeHeaderDelegate({
    required this.collapsed,
    required this.userName,
    required this.isAr,
    required this.onOrdersTap,
    required this.onToggleLocale,
    required this.onSignOut,
  });

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 180;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HamsaColors.bgDeep,
            HamsaColors.bgDeep.withOpacity(progress > 0.5 ? 1 : 0),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment:
                isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // In Arabic: buttons on left, greeting on right
                  // In English: greeting on left, buttons on right
                  if (!isAr) ...[
                    // Greeting (left in EN)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (progress < 0.5) ...[
                            Text(
                              'Good morning,',
                              style: HamsaText.body(size: 13, color: HamsaColors.muted),
                            ),
                            Text(
                              userName.isNotEmpty ? userName.split(' ').first : 'Guest',
                              style: HamsaText.heading(size: 24, color: HamsaColors.cream),
                            ),
                          ] else
                            Text('Hamsa Coffee',
                                style: HamsaText.heading(size: 18, color: HamsaColors.cream)),
                        ],
                      ),
                    ),
                    // Buttons (right in EN)
                    _ActionButtons(isAr: isAr, onToggleLocale: onToggleLocale, onOrdersTap: onOrdersTap, onSignOut: onSignOut),
                  ] else ...[
                    // Buttons (left in AR)
                    _ActionButtons(isAr: isAr, onToggleLocale: onToggleLocale, onOrdersTap: onOrdersTap, onSignOut: onSignOut),
                    // Greeting (right in AR)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (progress < 0.5) ...[
                            Text(
                              'مرحباً،',
                              style: HamsaText.arabic(size: 13, color: HamsaColors.muted),
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              userName.isNotEmpty ? userName.split(' ').first : 'ضيف',
                              style: HamsaText.heading(size: 24, color: HamsaColors.cream),
                              textDirection: TextDirection.rtl,
                            ),
                          ] else
                            Text('Hamsa Coffee',
                                style: HamsaText.heading(size: 18, color: HamsaColors.cream),
                                textDirection: TextDirection.rtl),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HomeHeaderDelegate old) =>
      old.collapsed != collapsed ||
      old.userName != userName ||
      old.isAr != isAr;
}

// ─── Action Buttons (language + orders + signout) ────────────
class _ActionButtons extends StatelessWidget {
  final bool isAr;
  final VoidCallback onToggleLocale;
  final VoidCallback onOrdersTap;
  final VoidCallback onSignOut;

  const _ActionButtons({
    required this.isAr,
    required this.onToggleLocale,
    required this.onOrdersTap,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIconBtn(
          onTap: onToggleLocale,
          child: Text(
            isAr ? 'EN' : 'ع',
            style: HamsaText.body(size: 13, weight: FontWeight.w700, color: HamsaColors.gold),
          ),
        ),
        const SizedBox(width: 8),
        _HeaderIconBtn(
          onTap: onOrdersTap,
          child: const Icon(Icons.receipt_long_outlined, color: HamsaColors.cream, size: 20),
        ),
        const SizedBox(width: 8),
        _HeaderIconBtn(
          onTap: onSignOut,
          child: const Icon(Icons.logout_rounded, color: HamsaColors.cream, size: 20),
        ),
      ],
    );
  }
}

// ─── Header Icon Button ──────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HeaderIconBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HamsaColors.border),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Category Row ────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final List<Category> categories;
  final String? selected;
  final String locale;
  final void Function(String?) onSelect;

  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.locale,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          // "All" chip
          _CategoryChip(
            label: locale == 'ar' ? 'الكل' : 'All',
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
            (cat) => _CategoryChip(
              label: cat.name(locale),
              icon: cat.icon,
              isSelected: selected == cat.id,
              onTap: () => onSelect(cat.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? HamsaColors.greenAccent
                : HamsaColors.bgElevated,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : HamsaColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Text(icon!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: HamsaText.body(
                  size: 15,
                  weight: FontWeight.w500,
                  color: isSelected
                      ? HamsaColors.bgDeep
                      : HamsaColors.offWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating Cart ───────────────────────────────────────────
class _CartFAB extends ConsumerWidget {
  final int count;
  final bool isAr;

  const _CartFAB({required this.count, required this.isAr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartTotalProvider);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.cart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: HamsaColors.greenAccent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: HamsaColors.greenAccent.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: HamsaColors.bgDeep.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: HamsaText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: HamsaColors.bgDeep,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isAr ? 'عرض السلة' : 'View Cart',
                style: HamsaText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: HamsaColors.bgDeep,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              'SAR ${total.toStringAsFixed(2)}',
              style: HamsaText.body(
                size: 14,
                weight: FontWeight.w700,
                color: HamsaColors.bgDeep,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 1.5, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }
}

// ─── Skeleton Card ───────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
