import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../providers/locale_provider.dart';
import '../../providers/order_provider.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).languageCode;
    final isAr = locale == 'ar';
    final ordersAsync = ref.watch(myOrdersProvider);

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
          isAr ? 'طلباتي' : 'My Orders',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'لا يوجد طلبات بعد' : 'No orders yet',
                    style: HamsaText.heading(
                        size: 20, color: HamsaColors.cream),
                  ),
                ],
              ),
            );
          }

          // Sort: newest first
          final sorted = [...orders]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return RefreshIndicator(
            color: HamsaColors.greenAccent,
            backgroundColor: HamsaColors.bgCard,
            onRefresh: () async =>
                ref.invalidate(myOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: sorted.length,
              itemBuilder: (_, i) => OrderTimelineCard(
                order: sorted[i],
                locale: locale,
                index: i,
              )
                  .animate(
                      delay: Duration(milliseconds: i * 60))
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.15, end: 0),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: HamsaColors.greenAccent),
        ),
        error: (e, _) => Center(
          child: Text(
            isAr ? 'حدث خطأ' : 'Error loading orders',
            style: HamsaText.body(color: HamsaColors.muted),
          ),
        ),
      ),
    );
  }
}

class OrderTimelineCard extends StatelessWidget {
  final Order order;
  final String locale;
  final int index;

  const OrderTimelineCard({
    super.key,
    required this.order,
    required this.locale,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = locale == 'ar';
    final status = order.status;

    final statusColor = switch (status) {
      OrderStatus.received => HamsaColors.statusReceived,
      OrderStatus.inProgress => HamsaColors.statusInProgress,
      OrderStatus.ready => HamsaColors.statusReady,
      OrderStatus.pickedUp => HamsaColors.statusPickedUp,
    };

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HamsaColors.border),
        ),
        child: Row(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Status color bar
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.only(
                  topLeft: isAr
                      ? Radius.zero
                      : const Radius.circular(18),
                  bottomLeft: isAr
                      ? Radius.zero
                      : const Radius.circular(18),
                  topRight: isAr
                      ? const Radius.circular(18)
                      : Radius.zero,
                  bottomRight: isAr
                      ? const Radius.circular(18)
                      : Radius.zero,
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  textDirection:
                      isAr ? TextDirection.rtl : TextDirection.ltr,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: isAr
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isAr ? "طلب" : "Order"} #${order.displayNumber}',
                          style: HamsaText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: HamsaColors.cream,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.items.length} ${isAr ? "عنصر" : "item(s)"}',
                          style: HamsaText.body(
                              size: 12, color: HamsaColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order.createdAt, isAr),
                          style: HamsaText.body(
                              size: 11, color: HamsaColors.subtle),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: isAr
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(100),
                            border: Border.all(
                                color: statusColor
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            isAr
                                ? status.labelAr()
                                : status.labelEn(),
                            style: HamsaText.body(
                              size: 11,
                              color: statusColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SAR ${order.totalPrice.toStringAsFixed(0)}',
                          style: HamsaText.price(size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: EdgeInsets.only(
                right: isAr ? 0 : 14,
                left: isAr ? 14 : 0,
              ),
              child: Icon(
                isAr
                    ? Icons.arrow_back_ios_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 13,
                color: HamsaColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt, bool isAr) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) {
      return isAr
          ? 'منذ ${diff.inMinutes} دقيقة'
          : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isAr
          ? 'منذ ${diff.inHours} ساعة'
          : '${diff.inHours}h ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
