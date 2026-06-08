import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final idx = state.indexWhere(
      (c) =>
          c.menuItemId == item.menuItemId &&
          _optionsMatch(c.selectedOptions, item.selectedOptions),
    );
    if (idx >= 0) {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(
        quantity: updated[idx].quantity + item.quantity,
      );
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void removeItem(int index) {
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final updated = [...state];
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = updated;
  }

  void clear() => state = [];

  double get total =>
      state.fold(0.0, (sum, item) => sum + item.subtotal);

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);

  bool _optionsMatch(
          Map<String, String> a, Map<String, String> b) =>
      a.length == b.length &&
      a.entries.every((e) => b[e.key] == e.value);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});
