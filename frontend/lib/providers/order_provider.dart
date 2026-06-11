import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import 'auth_provider.dart';

final _fs = FirebaseFirestore.instance;

// Customer: my orders — real-time stream
final myOrdersProvider = StreamProvider<List<Order>>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return const Stream.empty();
  return _fs
      .collection('orders')
      .where('customer_id', isEqualTo: userId)
      .snapshots()
      .map((snap) {
    final orders = snap.docs.map((d) => Order.fromFirestore(d)).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  });
});

// Admin: active queue (received + in_progress) — real-time stream
final activeOrdersProvider = StreamProvider<List<Order>>((ref) {
  return _fs
      .collection('orders')
      .where('status', whereIn: ['received', 'in_progress'])
      .snapshots()
      .map((snap) {
    final orders = snap.docs.map((d) => Order.fromFirestore(d)).toList();
    orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return orders;
  });
});

// Admin: all orders — real-time stream
final allOrdersProvider = StreamProvider<List<Order>>((ref) {
  return _fs
      .collection('orders')
      .snapshots()
      .map((snap) {
    final orders = snap.docs.map((d) => Order.fromFirestore(d)).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  });
});

// Single order — real-time stream
final singleOrderProvider = StreamProvider.family<Order, String>((ref, orderId) {
  return _fs
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .where((snap) => snap.exists)
      .map((snap) => Order.fromFirestore(snap));
});
