import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import 'auth_provider.dart';

// Customer: my orders
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return [];
  return api.getCustomerOrders(userId);
});

// Admin: active queue (received + in_progress)
final activeOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getActiveOrders();
});

// Admin: all orders (for history)
final allOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAllOrders();
});

// Single order refresh
final singleOrderProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getOrder(orderId);
});
