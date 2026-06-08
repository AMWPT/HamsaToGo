import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../models/order.dart';
import '../../providers/locale_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/hamsa_button.dart';

class OrderStatusScreen extends ConsumerWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).languageCode;
    final isAr = locale == 'ar';
    final orderAsync = ref.watch(singleOrderProvider(orderId));

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      appBar: AppBar(
        backgroundColor: HamsaColors.bgDeep,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: HamsaColors.muted, size: 22),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(
          isAr ? 'حالة الطلب' : 'Order Status',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: HamsaColors.muted, size: 20),
            onPressed: () => ref.invalidate(singleOrderProvider(orderId)),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => _OrderStatusBody(
            order: order, locale: locale, isAr: isAr),
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: HamsaColors.greenAccent),
        ),
        error: (_, __) => Center(
          child: Text(
            isAr ? 'خطأ في تحميل الطلب' : 'Error loading order',
            style: HamsaText.body(color: HamsaColors.muted),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusBody extends StatelessWidget {
  final Order order;
  final String locale;
  final bool isAr;

  const _OrderStatusBody({
    required this.order,
    required this.locale,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final status = order.status;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Big status indicator
          _StatusHero(status: status, isAr: isAr)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 40),

          // Progress timeline
          _ProgressTimeline(currentStatus: status, isAr: isAr)
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 36),

          // Order ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: HamsaColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HamsaColors.border),
            ),
            child: Row(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'رقم الطلب' : 'Order ID',
                  style: HamsaText.body(
                      size: 13, color: HamsaColors.muted),
                ),
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: HamsaText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: HamsaColors.cream,
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 300.ms)
              .fadeIn(duration: 350.ms),

          const SizedBox(height: 16),

          // Items summary
          _ItemsSummary(order: order, locale: locale, isAr: isAr)
              .animate(delay: 400.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 32),

          // CTA based on status
          if (status == OrderStatus.ready)
            Text(
              isAr
                  ? '🎉 طلبك جاهز! تفضل للاستلام'
                  : '🎉 Your order is ready! Head to the counter.',
              style: HamsaText.body(
                size: 15,
                weight: FontWeight.w600,
                color: HamsaColors.greenAccent,
              ),
              textAlign: TextAlign.center,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms)
                .then()
                .fadeOut(duration: 600.ms),

          const SizedBox(height: 16),

          if (status == OrderStatus.pickedUp)
            HamsaButton(
              label: isAr ? 'العودة للقائمة' : 'Back to Menu',
              onTap: () => context.go(AppRoutes.home),
              style: HamsaButtonStyle.secondary,
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 350.ms),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// ─── Status Hero ─────────────────────────────────────────────
class _StatusHero extends StatelessWidget {
  final OrderStatus status;
  final bool isAr;

  const _StatusHero({required this.status, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = switch (status) {
      OrderStatus.received => ('📋', HamsaColors.statusReceived),
      OrderStatus.inProgress => ('☕', HamsaColors.statusInProgress),
      OrderStatus.ready => ('✅', HamsaColors.statusReady),
      OrderStatus.pickedUp => ('🎉', HamsaColors.statusPickedUp),
    };

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 52)),
          ),
        )
            .animate(
              onPlay: status == OrderStatus.inProgress
                  ? (c) => c.repeat(reverse: true)
                  : null,
            )
            .then(delay: 300.ms)
            .scaleXY(
              begin: 1.0,
              end: status == OrderStatus.inProgress ? 1.05 : 1.0,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            ),

        const SizedBox(height: 20),

        Text(
          isAr ? status.labelAr() : status.labelEn(),
          style: HamsaText.heading(size: 26, color: HamsaColors.cream),
          textAlign: TextAlign.center,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        ),

        const SizedBox(height: 6),

        Text(
          _subtitle(status, isAr),
          style: HamsaText.body(size: 14, color: HamsaColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _subtitle(OrderStatus s, bool isAr) {
    if (isAr) {
      return switch (s) {
        OrderStatus.received =>
          'تم استلام طلبك، سنبدأ التحضير قريباً',
        OrderStatus.inProgress =>
          'طلبك قيد التحضير الآن',
        OrderStatus.ready =>
          'طلبك جاهز! توجه للكاونتر',
        OrderStatus.pickedUp =>
          'تم استلام طلبك. شكراً!',
      };
    }
    return switch (s) {
      OrderStatus.received =>
        'We received your order and will start soon',
      OrderStatus.inProgress => 'Your order is being prepared',
      OrderStatus.ready => 'Ready at the counter — come pick it up!',
      OrderStatus.pickedUp => 'Enjoyed! Thanks for visiting Hamsa.',
    };
  }
}

// ─── Progress Timeline ───────────────────────────────────────
class _ProgressTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  final bool isAr;

  const _ProgressTimeline({
    required this.currentStatus,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderStatus.received,
      OrderStatus.inProgress,
      OrderStatus.ready,
      OrderStatus.pickedUp,
    ];

    return Row(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isDone = step.step <= currentStatus.step;
        final isActive = step == currentStatus;

        return Expanded(
          child: Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Dot
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 18 : 14,
                    height: isActive ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? HamsaColors.greenAccent
                          : HamsaColors.bgElevated,
                      border: Border.all(
                        color: isDone
                            ? HamsaColors.greenAccent
                            : HamsaColors.borderStrong,
                        width: isActive ? 3 : 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: HamsaColors.greenAccent
                                    .withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shortLabel(step, isAr),
                    style: HamsaText.body(
                      size: 9,
                      color: isDone
                          ? HamsaColors.greenAccent
                          : HamsaColors.subtle,
                      weight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Connector line (not on last)
              if (i < steps.length - 1)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      color: step.step < currentStatus.step
                          ? HamsaColors.greenAccent
                          : HamsaColors.border,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _shortLabel(OrderStatus s, bool isAr) {
    if (isAr) {
      return switch (s) {
        OrderStatus.received => 'استُلم',
        OrderStatus.inProgress => 'جارٍ',
        OrderStatus.ready => 'جاهز',
        OrderStatus.pickedUp => 'مُستلم',
      };
    }
    return switch (s) {
      OrderStatus.received => 'Received',
      OrderStatus.inProgress => 'Making',
      OrderStatus.ready => 'Ready',
      OrderStatus.pickedUp => 'Done',
    };
  }
}

// ─── Items Summary ────────────────────────────────────────────
class _ItemsSummary extends StatelessWidget {
  final Order order;
  final String locale;
  final bool isAr;

  const _ItemsSummary({
    required this.order,
    required this.locale,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HamsaColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HamsaColors.border),
      ),
      child: Column(
        children: [
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}× ${item.name(locale)}',
                      style: HamsaText.body(
                          size: 13, color: HamsaColors.offWhite),
                      textDirection:
                          isAr ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                  Text(
                    'SAR ${item.subtotal.toStringAsFixed(0)}',
                    style: HamsaText.body(
                      size: 13,
                      color: HamsaColors.creamMuted,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: HamsaColors.border),

          Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'الإجمالي' : 'Total',
                style: HamsaText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: HamsaColors.cream,
                ),
              ),
              Text(
                'SAR ${order.totalPrice.toStringAsFixed(2)}',
                style: HamsaText.price(size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
