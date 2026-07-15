import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/order.dart';

/// Shared 4-phase order timeline:
/// Order Placed → Order Being Prepared → Order Ready for Pickup → Order Picked Up.
/// Used by both the customer order status screen and the staff order detail
/// screen so both roles always see the same phases.
class OrderProgressTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  final bool isAr;

  const OrderProgressTimeline({
    super.key,
    required this.currentStatus,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    const steps = [
      OrderStatus.received,
      OrderStatus.inProgress,
      OrderStatus.ready,
      OrderStatus.pickedUp,
    ];

    return Row(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isDone = step.step <= currentStatus.step;
        final isActive = step == currentStatus;

        return Expanded(
          child: Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot + label — Flexible so the fixed-width label can shrink
              // instead of overflowing on very narrow screens.
              Flexible(
                child: Column(
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
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 58,
                    child: Text(
                      step.label(isAr),
                      style: HamsaText.body(
                        size: 9,
                        color: isDone
                            ? HamsaColors.greenAccent
                            : HamsaColors.subtle,
                        weight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      textDirection:
                          isAr ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                ],
                ),
              ),

              // Connector line (not on last)
              if (i < steps.length - 1)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
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
}
