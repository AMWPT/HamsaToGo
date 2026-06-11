import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/order_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(activeOrdersProvider);

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: HamsaText.display(
                              size: 32, color: HamsaColors.cream),
                        ),
                        Text(
                          'Live order queue',
                          style: HamsaText.body(
                              size: 13, color: HamsaColors.muted),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    // Nav icons
                    Row(
                      children: [
                        _NavIcon(
                          icon: Icons.menu_book_outlined,
                          label: 'Menu',
                          onTap: () => context.push(AppRoutes.menuManager),
                        ),
                        const SizedBox(width: 8),
                        _NavIcon(
                          icon: Icons.history_rounded,
                          label: 'History',
                          onTap: () => context.push(AppRoutes.history),
                        ),
                        const SizedBox(width: 8),
                        _NavIcon(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          onTap: () => ref
                              .read(authProvider.notifier)
                              .logout(),
                        ),
                      ],
                    ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: ordersAsync.when(
              data: (orders) => _StatsRow(orders: orders)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox(height: 80),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text(
                'ACTIVE ORDERS',
                style: HamsaText.caption(
                    size: 11, color: HamsaColors.muted),
              ),
            ),
          ),

          // Orders list
          ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyQueue()
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 400.ms),
                );
              }

              return SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => AdminOrderCard(
                      order: orders[i],
                      index: i,
                    )
                        .animate(
                          delay: Duration(
                              milliseconds: 300 + i * 70),
                        )
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.15, end: 0),
                    childCount: orders.length,
                  ),
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Column(
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    height: 90,
                    decoration: BoxDecoration(
                      color: HamsaColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 80))
                      .shimmer(duration: 1200.ms),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Failed to load orders',
                    style: HamsaText.body(color: HamsaColors.muted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<Order> orders;
  const _StatsRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    final received =
        orders.where((o) => o.status == OrderStatus.received).length;
    final inProgress =
        orders.where((o) => o.status == OrderStatus.inProgress).length;
    final ready =
        orders.where((o) => o.status == OrderStatus.ready).length;
    final total = orders.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              label: 'New',
              value: '$received',
              color: HamsaColors.statusReceived,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              label: 'Preparing',
              value: '$inProgress',
              color: HamsaColors.statusInProgress,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              label: 'Ready',
              value: '$ready',
              color: HamsaColors.statusReady,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              label: 'Queue',
              value: '$total',
              color: HamsaColors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: HamsaText.display(size: 28, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                HamsaText.body(size: 11, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Order Card ────────────────────────────────────────
class AdminOrderCard extends ConsumerWidget {
  final Order order;
  final int index;

  const AdminOrderCard({
    super.key,
    required this.order,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final status = order.status;

    final statusColor = switch (status) {
      OrderStatus.received => HamsaColors.statusReceived,
      OrderStatus.inProgress => HamsaColors.statusInProgress,
      OrderStatus.ready => HamsaColors.statusReady,
      OrderStatus.pickedUp => HamsaColors.statusPickedUp,
    };

    final nextStatus = status.next;

    return GestureDetector(
      onTap: () => context.push('/admin/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HamsaColors.border),
        ),
        child: Row(
          children: [
            // Left color bar
            Container(
              width: 5,
              height: 90,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Order info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.displayNumber}',
                            style: HamsaText.body(
                              size: 13,
                              weight: FontWeight.w700,
                              color: HamsaColors.cream,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.items.map((i) => '${i.quantity}× ${i.nameEn}').join(', '),
                            style: HamsaText.body(
                                size: 11, color: HamsaColors.muted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              status.label(isAr),
                              style: HamsaText.body(
                                size: 10,
                                color: statusColor,
                                weight: FontWeight.w600,
                              ),
                              textDirection: isAr
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick action button
                    if (nextStatus != null)
                      GestureDetector(
                        onTap: () => _updateStatus(context, ref, nextStatus),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _nextLabel(nextStatus, isAr),
                            style: HamsaText.body(
                              size: 11,
                              weight: FontWeight.w700,
                              color: statusColor,
                            ),
                            textDirection: isAr
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Arrow
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: HamsaColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, OrderStatus next) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.updateOrderStatus(order.id, next);
      // Stream auto-updates — no manual refresh needed
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: HamsaColors.error.withValues(alpha: 0.9),
          ),
        );
      }
    }
  }

  // Action labels — worded as the action that moves the order to `next`,
  // so they can't be mistaken for the order's current status.
  String _nextLabel(OrderStatus next, bool isAr) => switch (next) {
        OrderStatus.received => isAr ? 'تقديم' : 'Place',
        OrderStatus.inProgress => isAr ? 'بدء التحضير' : 'Start Preparing',
        OrderStatus.ready => isAr ? 'تأكيد الجاهزية' : 'Mark Ready',
        OrderStatus.pickedUp => isAr ? 'تأكيد الاستلام' : 'Mark Picked Up',
      };
}

// ─── Empty Queue ─────────────────────────────────────────────
class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            const Text('☕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Queue is empty',
              style: HamsaText.heading(
                  size: 20, color: HamsaColors.cream),
            ),
            const SizedBox(height: 8),
            Text(
              'New orders will appear here',
              style:
                  HamsaText.body(size: 13, color: HamsaColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Icon ────────────────────────────────────────────────
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HamsaColors.border),
        ),
        child: Icon(icon, color: HamsaColors.cream, size: 18),
      ),
    );
  }
}
