import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/hamsa_button.dart';
import '../../widgets/order_progress_timeline.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(singleOrderProvider(orderId));

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
          'Order Details',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
      ),
      body: orderAsync.when(
        data: (order) => _Body(order: order),
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: HamsaColors.greenAccent),
        ),
        error: (_, __) => const Center(
          child: Text('Error', style: TextStyle(color: HamsaColors.muted)),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final Order order;
  const _Body({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final status = order.status;
    final nextStatus = status.next;

    final statusColor = switch (status) {
      OrderStatus.received => HamsaColors.statusReceived,
      OrderStatus.inProgress => HamsaColors.statusInProgress,
      OrderStatus.ready => HamsaColors.statusReady,
      OrderStatus.pickedUp => HamsaColors.statusPickedUp,
    };

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Order ID + Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.displayNumber}',
                            style: HamsaText.heading(
                                size: 22, color: HamsaColors.cream),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(order.createdAt),
                            style: HamsaText.body(
                                size: 12, color: HamsaColors.muted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          status.label(isAr),
                          style: HamsaText.body(
                            size: 13,
                            color: statusColor,
                            weight: FontWeight.w700,
                          ),
                          textDirection:
                              isAr ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Progress timeline — same 4 phases the customer sees
                OrderProgressTimeline(currentStatus: status, isAr: isAr)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                Text(
                  'ITEMS',
                  style: HamsaText.caption(
                      size: 11, color: HamsaColors.muted),
                ),

                const SizedBox(height: 12),

                // Items list
                ...order.items.asMap().entries.map(
                  (entry) => _ItemRow(orderItem: entry.value)
                      .animate(
                        delay: Duration(
                            milliseconds: 100 + entry.key * 60),
                      )
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1, end: 0),
                ),

                const Divider(
                    color: HamsaColors.border, height: 32),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: HamsaText.caption(
                          size: 11, color: HamsaColors.muted),
                    ),
                    Text(
                      'SAR ${order.totalPrice.toStringAsFixed(2)}',
                      style: HamsaText.price(size: 22),
                    ),
                  ],
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 350.ms),

                const SizedBox(height: 16),

                // Payment method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAYMENT',
                      style: HamsaText.caption(
                          size: 11, color: HamsaColors.muted),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _paymentIcon(order.paymentMethod),
                          size: 16,
                          color: HamsaColors.creamMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.paymentMethod?.label(isAr) ??
                              (isAr ? 'غير محدد' : 'Not specified'),
                          style: HamsaText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: HamsaColors.offWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 350.ms),

                if (order.notes != null &&
                    order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: HamsaColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HamsaColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTES',
                          style: HamsaText.caption(
                              size: 10, color: HamsaColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.notes!,
                          style: HamsaText.body(
                              size: 14, color: HamsaColors.offWhite),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Action button at bottom
        if (nextStatus != null)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            decoration: const BoxDecoration(
              color: HamsaColors.bgCard,
              border: Border(top: BorderSide(color: HamsaColors.border)),
            ),
            child: HamsaButton(
              label: _actionLabel(nextStatus, isAr),
              onTap: () => _advance(context, ref, nextStatus),
              style: nextStatus == OrderStatus.ready
                  ? HamsaButtonStyle.gold
                  : HamsaButtonStyle.primary,
            ),
          ),
      ],
    );
  }

  Future<void> _advance(
      BuildContext context, WidgetRef ref, OrderStatus next) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.updateOrderStatus(order.id, next);
      // Streams auto-update — stay on this screen so staff can
      // watch the timeline advance and press the next step.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // Action labels — worded as the action that moves the order to `next`,
  // so they can't be mistaken for the order's current status.
  String _actionLabel(OrderStatus next, bool isAr) => switch (next) {
        OrderStatus.received =>
          isAr ? 'تقديم الطلب' : 'Place Order',
        OrderStatus.inProgress =>
          isAr ? 'بدء تحضير الطلب' : 'Start Preparing Order',
        OrderStatus.ready =>
          isAr ? 'تأكيد جاهزية الطلب للاستلام' : 'Mark as Ready for Pickup',
        OrderStatus.pickedUp =>
          isAr ? 'تأكيد استلام الطلب' : 'Mark as Picked Up',
      };

  IconData _paymentIcon(PaymentMethod? m) => switch (m) {
        PaymentMethod.mada => Icons.account_balance_rounded,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.applePay => Icons.apple_rounded,
        PaymentMethod.stcPay => Icons.account_balance_wallet_rounded,
        null => Icons.help_outline_rounded,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItemModel orderItem;
  const _ItemRow({required this.orderItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HamsaColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${orderItem.quantity}× ${orderItem.nameEn}',
                    style: HamsaText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: HamsaColors.cream,
                    ),
                  ),
                  if (orderItem.nameAr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      orderItem.nameAr,
                      style: HamsaText.arabic(
                          size: 12, color: HamsaColors.muted),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                  if (orderItem.selectedOptions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: orderItem.selectedOptions.entries
                          .map<Widget>(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: HamsaColors.bgElevated,
                                borderRadius:
                                    BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${e.key}: ${e.value}',
                                style: HamsaText.body(
                                    size: 10,
                                    color: HamsaColors.muted),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (orderItem.notes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📝 ${orderItem.notes}',
                      style: HamsaText.body(
                          size: 11, color: HamsaColors.creamMuted),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              'SAR ${orderItem.subtotal.toStringAsFixed(0)}',
              style: HamsaText.price(size: 15),
            ),
          ],
        ),
      ),
    );
  }
}
