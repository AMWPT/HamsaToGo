import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/hamsa_button.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String? heroTag;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.heroTag,
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  int _quantity = 1;
  final Map<String, String> _selectedOptions = {};
  Crop? _selectedCrop;
  String? _notes;

  /// Stable key used to carry the chosen crop through cart → order.
  static const _cropKey = 'Crop';

  /// Total price modifier from selected options (e.g. +5 for coconut milk)
  double _calcModifier(MenuItem item) {
    double extra = 0;
    for (final opt in item.options) {
      final chosen = _selectedOptions[opt.name];
      if (chosen != null) {
        extra += opt.priceModifiers[chosen] ?? 0;
      }
    }
    return extra;
  }

  void _addToCart(MenuItem item, String locale) {
    final isAr = locale == 'ar';

    // Crop is required whenever the item has crops configured.
    if (item.crops.isNotEmpty && _selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'الرجاء اختيار المحصول' : 'Please choose a coffee crop',
            style: HamsaText.body(size: 14, color: HamsaColors.bgDeep),
          ),
          backgroundColor: HamsaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final modifier = _calcModifier(item);
    final options = Map<String, String>.from(_selectedOptions);
    if (_selectedCrop != null) {
      options[_cropKey] = _selectedCrop!.name(locale);
    }
    final cartItem = CartItem(
      menuItemId: item.id,
      nameEn: item.nameEn,
      nameAr: item.nameAr,
      unitPrice: item.price + modifier,
      quantity: _quantity,
      selectedOptions: options,
      notes: _notes?.isNotEmpty == true ? _notes : null,
    );
    ref.read(cartProvider.notifier).addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale == 'ar' ? 'تمت الإضافة إلى السلة ✓' : 'Added to cart ✓',
          style: HamsaText.body(size: 14, color: HamsaColors.bgDeep),
        ),
        backgroundColor: HamsaColors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isAr = locale == 'ar';
    final api = ref.watch(apiServiceProvider);

    return Scaffold(
      backgroundColor: HamsaColors.bgDeep,
      body: FutureBuilder(
        future: api.getMenuItem(widget.itemId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: HamsaColors.greenAccent),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Text(
                isAr ? 'حدث خطأ' : 'Error loading item',
                style: HamsaText.body(color: HamsaColors.muted),
              ),
            );
          }

          final item = snap.data!;
          final modifier = _calcModifier(item);
          final unitPrice = item.price + modifier;
          final totalPrice = unitPrice * _quantity;

          return SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: HamsaColors.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: HamsaColors.border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: HamsaColors.cream,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                    children: [
                      // Name + base price row
                      Row(
                        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name(locale),
                              style: HamsaText.heading(
                                  size: 30, color: HamsaColors.cream),
                              textDirection:
                                  isAr ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Show base + modifier if modifier > 0
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'SAR ${unitPrice.toStringAsFixed(0)}',
                                style: HamsaText.price(size: 26),
                              ),
                              if (modifier > 0)
                                Text(
                                  '+${modifier.toStringAsFixed(0)} SAR',
                                  style: HamsaText.body(
                                    size: 13,
                                    color: HamsaColors.greenAccent,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),

                      // Coffee crop — required selection when crops exist
                      if (item.crops.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _CropSelector(
                          crops: item.crops,
                          selected: _selectedCrop,
                          isAr: isAr,
                          locale: locale,
                          onSelect: (c) =>
                              setState(() => _selectedCrop = c),
                        ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                      ],

                      const SizedBox(height: 32),

                      // Options
                      if (item.options.isNotEmpty) ...[
                        ...item.options.asMap().entries.map(
                          (entry) {
                            final option = entry.value;
                            return _OptionGroup(
                              option: option,
                              selected: _selectedOptions[option.name],
                              isAr: isAr,
                              onSelect: (choice) =>
                                  setState(() {
                                    _selectedOptions[option.name] = choice;
                                  }),
                            ).animate(
                              delay: Duration(
                                  milliseconds: 100 + entry.key * 80),
                            ).fadeIn(duration: 350.ms);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Notes
                      _NotesField(
                        isAr: isAr,
                        onChanged: (v) => _notes = v,
                      )
                          .animate(delay: 280.ms)
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 36),

                      // Quantity + Add to cart
                      Row(
                        children: [
                          _QuantityControl(
                            quantity: _quantity,
                            onDecrement: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                            onIncrement: () => setState(() => _quantity++),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: HamsaButton(
                              label: isAr
                                  ? 'أضف إلى السلة — SAR ${totalPrice.toStringAsFixed(0)}'
                                  : 'Add to Cart — SAR ${totalPrice.toStringAsFixed(0)}',
                              onTap: () => _addToCart(item, locale),
                            ),
                          ),
                        ],
                      )
                          .animate(delay: 330.ms)
                          .fadeIn(duration: 400.ms),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Crop Selector (required) ────────────────────────────────
class _CropSelector extends StatelessWidget {
  final List<Crop> crops;
  final Crop? selected;
  final bool isAr;
  final String locale;
  final void Function(Crop) onSelect;

  const _CropSelector({
    required this.crops,
    required this.selected,
    required this.isAr,
    required this.locale,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_cafe_outlined,
                color: HamsaColors.greenAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              isAr ? 'المحصول' : 'Coffee Crop',
              style: HamsaText.body(
                size: 15,
                weight: FontWeight.w600,
                color: HamsaColors.muted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isAr ? '(مطلوب)' : '(required)',
              style: HamsaText.body(size: 12, color: HamsaColors.error),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          children: crops.map((crop) {
            final isSelected = selected == crop;
            return GestureDetector(
              onTap: () => onSelect(crop),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? HamsaColors.greenAccent.withValues(alpha: 0.15)
                      : HamsaColors.bgElevated,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? HamsaColors.greenAccent
                        : HamsaColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  crop.name(locale),
                  style: isAr
                      ? HamsaText.arabic(
                          size: 15,
                          color: isSelected
                              ? HamsaColors.greenAccent
                              : HamsaColors.offWhite,
                        )
                      : HamsaText.body(
                          size: 15,
                          color: isSelected
                              ? HamsaColors.greenAccent
                              : HamsaColors.offWhite,
                          weight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Option Group ─────────────────────────────────────────────
class _OptionGroup extends StatelessWidget {
  final MenuOption option;
  final String? selected;
  final bool isAr;
  final void Function(String) onSelect;

  const _OptionGroup({
    required this.option,
    required this.selected,
    required this.isAr,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment:
            isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            option.name,
            style: HamsaText.body(
              size: 15,
              weight: FontWeight.w600,
              color: HamsaColors.muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            children: option.choices.map((choice) {
              final isSelected = selected == choice;
              final modifier = option.priceModifiers[choice] ?? 0;
              return GestureDetector(
                onTap: () => onSelect(choice),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? HamsaColors.greenAccent.withValues(alpha: 0.15)
                        : HamsaColors.bgElevated,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? HamsaColors.greenAccent
                          : HamsaColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        choice,
                        style: HamsaText.body(
                          size: 15,
                          color: isSelected
                              ? HamsaColors.greenAccent
                              : HamsaColors.offWhite,
                          weight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Notes Field ─────────────────────────────────────────────
class _NotesField extends StatelessWidget {
  final bool isAr;
  final void Function(String) onChanged;

  const _NotesField({required this.isAr, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
          style: HamsaText.body(
            size: 15,
            weight: FontWeight.w600,
            color: HamsaColors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: onChanged,
          maxLines: 2,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          style: HamsaText.body(size: 15, color: HamsaColors.cream),
          decoration: InputDecoration(
            hintText: isAr
                ? 'مثال: سكر قليل، بدون حليب...'
                : 'e.g. less sugar, no ice...',
            hintStyle: HamsaText.body(size: 14, color: HamsaColors.subtle),
            filled: true,
            fillColor: HamsaColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HamsaColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HamsaColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: HamsaColors.greenAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quantity Control ────────────────────────────────────────
class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: HamsaColors.bgElevated,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: HamsaColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                '$quantity',
                style: HamsaText.body(
                  size: 18,
                  weight: FontWeight.w600,
                  color: HamsaColors.cream,
                ),
              ),
            ),
          ),
          _QBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(icon, color: HamsaColors.cream, size: 22),
      ),
    );
  }
}
