import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final String locale;
  final int index;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.locale,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'item-${item.id}';
    final isAr = locale == 'ar';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => context.push(
          '/item/${item.id}',
          extra: {'heroTag': heroTag},
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: HamsaColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HamsaColors.border),
          ),
          child: Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: isAr
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      item.name(locale),
                      style: HamsaText.body(
                        size: 18,
                        weight: FontWeight.w600,
                        color: HamsaColors.cream,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection:
                          isAr ? TextDirection.rtl : TextDirection.ltr,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection:
                          isAr ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        // Price
                        Text(
                          'SAR ${item.price.toStringAsFixed(0)}',
                          style: HamsaText.price(size: 20),
                        ),

                        // Options badge
                        if (item.options.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: HamsaColors.greenBrand.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: HamsaColors.border),
                            ),
                            child: Text(
                              isAr ? 'خيارات' : 'Customizable',
                              style: HamsaText.body(
                                size: 12,
                                color: HamsaColors.greenAccent,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Padding(
                padding: EdgeInsets.only(
                  left: isAr ? 0 : 10,
                  right: isAr ? 10 : 0,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: HamsaColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
