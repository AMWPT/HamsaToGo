import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moyasar/moyasar.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/order.dart';
import '../../services/moyasar_service.dart';
import '../../widgets/hamsa_button.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isPlacing = false;
  PaymentMethod _method = PaymentMethod.card;

  bool get _isAr => ref.read(localeProvider).languageCode == 'ar';

  // ── Step 1: user taps "Pay & Place Order" — start the Moyasar flow ────
  Future<void> _startPayment() async {
    final cart = ref.read(cartProvider);
    final auth = ref.read(authProvider);
    if (cart.isEmpty || auth.user == null) return;

    final total = ref.read(cartTotalProvider);
    final config = MoyasarService.buildConfig(
      amountSar: total,
      description: 'Hamsa To Go order — ${auth.user!.fullName}',
      metadata: {'customer_id': auth.user!.id},
    );

    // Apple Pay / Samsung Pay show their own native button widget instead —
    // this path is only reached for mada/card, which uses the card form sheet.
    final isAr = _isAr;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: HamsaColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header — explicit back arrow instead of swipe-to-dismiss,
              // so an accidental swipe mid-typing doesn't lose card details.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
                child: Row(
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    IconButton(
                      icon: Icon(
                        isAr
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        color: HamsaColors.cream,
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                    Expanded(
                      child: Column(
                        // The app is RTL-wide in Arabic, so `start` already
                        // resolves to the right edge — flipping to `end`
                        // here would double-flip back to the left.
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'الدفع بالبطاقة' : 'Card Payment',
                            style: HamsaText.heading(size: 17, color: HamsaColors.cream),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              const Icon(Icons.lock_rounded,
                                  size: 12, color: HamsaColors.greenAccent),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'دفع آمن ومشفّر' : 'Secure encrypted payment',
                                style: HamsaText.body(size: 11, color: HamsaColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card form — Moyasar renders its own white input fields, so
              // we frame it in a rounded elevated surface instead of leaving
              // it floating directly on the dark sheet background.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HamsaColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HamsaColors.border),
                  ),
                  child: CreditCard(
                    config: config,
                    onPaymentResult: (result) {
                      Navigator.of(sheetCtx).pop();
                      _handlePaymentResult(result);
                    },
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 2: Apple Pay / Samsung Pay widgets call this directly ────────
  void _handlePaymentResult(dynamic result) {
    if (result is PaymentResponse) {
      switch (result.status) {
        case PaymentStatus.paid:
        case PaymentStatus.captured:
          _completeOrder(result.id);
          return;
        case PaymentStatus.initiated:
        case PaymentStatus.authorized:
          // 3DS challenge or manual-capture step handled internally by the
          // SDK; nothing to do here — it will call back again with the
          // final status.
          return;
        case PaymentStatus.failed:
          break;
      }
    }
    if (!mounted) return;
    _showError(_isAr
        ? 'تعذّر إتمام الدفع. حاول مرة أخرى.'
        : 'Payment could not be completed. Please try again.');
  }

  // ── Step 3: payment confirmed — create the order in the backend ──────
  Future<void> _completeOrder(String paymentId) async {
    final cart = ref.read(cartProvider);
    final auth = ref.read(authProvider);
    if (cart.isEmpty || auth.user == null) return;

    setState(() => _isPlacing = true);
    try {
      final api = ref.read(apiServiceProvider);
      final order = await api.placeOrder(
        customerId: auth.user!.id,
        customerName: auth.user!.fullName,
        items: cart,
        paymentMethod: _method,
        paymentId: paymentId,
      );
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.pushReplacement('/orders/${order.id}');
    } catch (e) {
      if (!mounted) return;
      _showError(_isAr
          ? 'تم الدفع لكن تعذّر إنشاء الطلب. تواصل مع الدعم.'
          : 'Payment succeeded but the order could not be created. Please contact support.');
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: HamsaColors.error.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final isAr = locale == 'ar';

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
          isAr ? 'سلة المشتريات' : 'Your Cart',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: Text(
                isAr ? 'مسح الكل' : 'Clear all',
                style: HamsaText.body(
                    size: 13, color: HamsaColors.error),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCart(isAr: isAr)
          : Column(
              children: [
                // Items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: cart.length,
                    itemBuilder: (_, i) => _CartItemTile(
                      item: cart[i],
                      locale: locale,
                      index: i,
                      onRemove: () =>
                          ref.read(cartProvider.notifier).removeItem(i),
                      onDecrement: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(i, cart[i].quantity - 1),
                      onIncrement: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(i, cart[i].quantity + 1),
                    )
                        .animate(delay: Duration(milliseconds: i * 60))
                        .fadeIn(duration: 350.ms)
                        .slideX(begin: 0.1, end: 0),
                  ),
                ),

                // Summary + CTA
                _OrderSummary(
                  total: total,
                  isAr: isAr,
                  isLoading: _isPlacing,
                  selectedMethod: _method,
                  onSelectMethod: (m) => setState(() => _method = m),
                  onPlaceOrder: _startPayment,
                  moyasarConfig: MoyasarService.buildConfig(
                    amountSar: total,
                    description: 'Hamsa To Go order',
                  ),
                  onPaymentResult: _handlePaymentResult,
                ),
              ],
            ),
    );
  }
}

// ─── Cart Item Tile ───────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final String locale;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartItemTile({
    required this.item,
    required this.locale,
    required this.index,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = locale == 'ar';

    return Dismissible(
      key: Key('cart-$index-${item.menuItemId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: HamsaColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: HamsaColors.error, size: 22),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HamsaColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HamsaColors.border),
        ),
        child: Row(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: isAr
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name(locale),
                    style: HamsaText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: HamsaColors.cream,
                    ),
                    textDirection:
                        isAr ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  if (item.selectedOptions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.selectedOptions.values.join(' · '),
                      style: HamsaText.body(
                          size: 12, color: HamsaColors.muted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'SAR ${item.subtotal.toStringAsFixed(2)}',
                    style: HamsaText.price(size: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Quantity
            _MiniQuantity(
              quantity: item.quantity,
              onDecrement: onDecrement,
              onIncrement: onIncrement,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniQuantity extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _MiniQuantity({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HamsaColors.bgElevated,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: HamsaColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Icon(Icons.remove_rounded,
                  color: HamsaColors.cream, size: 16),
            ),
          ),
          Text(
            '$quantity',
            style: HamsaText.body(
              size: 14,
              weight: FontWeight.w600,
              color: HamsaColors.cream,
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Icon(Icons.add_rounded,
                  color: HamsaColors.cream, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Summary ────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final double total;
  final bool isAr;
  final bool isLoading;
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onSelectMethod;
  final VoidCallback onPlaceOrder;
  final PaymentConfig moyasarConfig;
  final void Function(dynamic result) onPaymentResult;

  const _OrderSummary({
    required this.total,
    required this.isAr,
    required this.isLoading,
    required this.selectedMethod,
    required this.onSelectMethod,
    required this.onPlaceOrder,
    required this.moyasarConfig,
    required this.onPaymentResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: HamsaColors.bgCard,
        border: Border(
          top: BorderSide(color: HamsaColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment method
          Align(
            alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              isAr ? 'طريقة الدفع' : 'Payment method',
              style: HamsaText.body(
                size: 13,
                weight: FontWeight.w600,
                color: HamsaColors.creamMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PaymentMethodSelector(
            selected: selectedMethod,
            isAr: isAr,
            onSelect: onSelectMethod,
          ),

          const SizedBox(height: 20),

          // Total row
          Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'المجموع' : 'Total',
                style: HamsaText.body(
                  size: 16,
                  weight: FontWeight.w600,
                  color: HamsaColors.creamMuted,
                ),
              ),
              Text(
                'SAR ${total.toStringAsFixed(2)}',
                style: HamsaText.price(size: 24),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            isAr
                ? '* سيتم الدفع إلكترونياً بالطريقة المختارة'
                : '* Payment is collected online via the selected method',
            style: HamsaText.body(size: 11, color: HamsaColors.subtle),
            textAlign: isAr ? TextAlign.right : TextAlign.left,
          ),

          const SizedBox(height: 20),

          _PayCta(
            isAr: isAr,
            isLoading: isLoading,
            method: selectedMethod,
            onPlaceOrder: onPlaceOrder,
            moyasarConfig: moyasarConfig,
            onPaymentResult: onPaymentResult,
          ),
        ],
      ),
    );
  }
}

// ─── Pay CTA ───────────────────────────────────────────────────
// mada/card use the standard button which opens the card-entry sheet.
// Apple Pay / Samsung Pay render their own native button widget — tapping
// it triggers the OS payment sheet directly, no intermediate tap needed.
class _PayCta extends StatelessWidget {
  final bool isAr;
  final bool isLoading;
  final PaymentMethod method;
  final VoidCallback onPlaceOrder;
  final PaymentConfig moyasarConfig;
  final void Function(dynamic result) onPaymentResult;

  const _PayCta({
    required this.isAr,
    required this.isLoading,
    required this.method,
    required this.onPlaceOrder,
    required this.moyasarConfig,
    required this.onPaymentResult,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return HamsaButton(
        label: isAr ? 'جارٍ إنشاء الطلب...' : 'Placing order...',
        onTap: null,
        isLoading: true,
        icon: Icons.lock_outline_rounded,
      );
    }

    switch (method) {
      case PaymentMethod.applePay:
        return SizedBox(
          height: 54,
          child: ApplePay(
            config: moyasarConfig,
            onPaymentResult: onPaymentResult,
          ),
        );
      // Samsung Pay is not offered; unreachable, falls through to the
      // card button just in case.
      case PaymentMethod.samsungPay:
      case PaymentMethod.mada:
      case PaymentMethod.card:
        return HamsaButton(
          label: isAr ? 'الدفع وتأكيد الطلب' : 'Pay & Place Order',
          onTap: onPlaceOrder,
          icon: Icons.lock_outline_rounded,
        );
    }
  }
}

// ─── Payment Method Selector ──────────────────────────────────
class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final bool isAr;
  final ValueChanged<PaymentMethod> onSelect;

  const _PaymentMethodSelector({
    required this.selected,
    required this.isAr,
    required this.onSelect,
  });

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.mada:
        return Icons.account_balance_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.applePay:
        return Icons.apple_rounded;
      case PaymentMethod.samsungPay:
        return Icons.account_balance_wallet_rounded;
    }
  }

  // "Card" covers both mada and credit cards — Moyasar's card form
  // auto-detects mada from the card number and shows its network icon,
  // so there's no need for a separate mada chip.
  // Apple Pay is iOS-only. Samsung Pay is not offered.
  bool _availableOnPlatform(PaymentMethod m) {
    if (m == PaymentMethod.mada) return false;
    if (m == PaymentMethod.applePay) return Platform.isIOS;
    if (m == PaymentMethod.samsungPay) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final methods = PaymentMethod.values.where(_availableOnPlatform);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: methods.map((m) {
        final isSelected = m == selected;
        return GestureDetector(
          onTap: () => onSelect(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? HamsaColors.greenAccent.withValues(alpha: 0.15)
                  : HamsaColors.bgElevated,
              borderRadius: BorderRadius.circular(14),
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
                Icon(
                  _iconFor(m),
                  size: 18,
                  color: isSelected
                      ? HamsaColors.greenAccent
                      : HamsaColors.creamMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  m.label(isAr),
                  style: HamsaText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: isSelected
                        ? HamsaColors.cream
                        : HamsaColors.offWhite,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Empty Cart ───────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final bool isAr;
  const _EmptyCart({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 64))
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms,
                  curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          Text(
            isAr ? 'سلتك فارغة' : 'Your cart is empty',
            style: HamsaText.heading(size: 22, color: HamsaColors.cream),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'أضف بعض العناصر من القائمة'
                : 'Add some items from the menu',
            style: HamsaText.body(color: HamsaColors.muted),
          ),
          const SizedBox(height: 32),
          HamsaButton(
            label: isAr ? 'استعرض القائمة' : 'Browse Menu',
            onTap: () => context.go(AppRoutes.home),
            width: 200,
          ),
        ],
      ),
    );
  }
}
