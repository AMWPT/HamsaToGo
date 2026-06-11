import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

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
          'Order History',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          // Sort newest first, show completed
          final sorted = [...orders]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (sorted.isEmpty) {
            return Center(
              child: Text(
                'No orders yet',
                style: HamsaText.body(color: HamsaColors.muted),
              ),
            );
          }

          // Group by date
          final groups = <String, List<Order>>{};
          for (final o in sorted) {
            final key = _dateLabel(o.createdAt);
            groups.putIfAbsent(key, () => []).add(o);
          }

          return RefreshIndicator(
            color: HamsaColors.greenAccent,
            backgroundColor: HamsaColors.bgCard,
            onRefresh: () async => ref.invalidate(allOrdersProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: groups.entries.toList().asMap().entries.map(
                (e) {
                  final sectionIdx = e.key;
                  final section = e.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          section.key,
                          style: HamsaText.caption(
                              size: 11, color: HamsaColors.muted),
                        ),
                      )
                          .animate(
                              delay: Duration(
                                  milliseconds: sectionIdx * 40))
                          .fadeIn(duration: 300.ms),
                      ...section.value.asMap().entries.map(
                        (entry) => _HistoryCard(order: entry.value)
                            .animate(
                              delay: Duration(
                                  milliseconds:
                                      sectionIdx * 40 +
                                          entry.key * 50),
                            )
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: HamsaColors.greenAccent),
        ),
        error: (_, __) => Center(
          child: Text(
            'Error loading history',
            style: HamsaText.body(color: HamsaColors.muted),
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _HistoryCard extends StatelessWidget {
  final Order order;
  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.pickedUp => HamsaColors.greenAccent,
      OrderStatus.ready => HamsaColors.statusReady,
      _ => HamsaColors.muted,
    };

    return GestureDetector(
      onTap: () => context.push('/admin/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HamsaColors.border),
        ),
        child: Row(
          children: [
            // Green stripe
            Container(
              width: 4,
              height: 68,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    '#${order.displayNumber}',
                    style: HamsaText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: HamsaColors.cream,
                    ),
                  ),
                  Text(
                    '${order.items.length} item(s) · SAR ${order.totalPrice.toStringAsFixed(0)}',
                    style: HamsaText.body(
                        size: 12, color: HamsaColors.muted),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeStr(order.createdAt),
                  style:
                      HamsaText.body(size: 11, color: HamsaColors.subtle),
                ),
                const SizedBox(height: 4),
                Text(
                  order.status.labelEn(),
                  style: HamsaText.body(
                    size: 11,
                    color: statusColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeStr(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
