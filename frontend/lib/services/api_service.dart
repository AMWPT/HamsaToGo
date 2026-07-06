import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.timeout,
      receiveTimeout: ApiConstants.timeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — attach a FRESH Firebase ID token on each request.
    // getIdToken() returns a cached token and auto-refreshes it when it's
    // near expiry, so the backend always receives a valid, unexpired token.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Don't overwrite a token explicitly supplied for this request
        // (e.g. a force-refreshed token for account deletion).
        if (options.headers['Authorization'] == null) {
          try {
            final token =
                await FirebaseAuth.instance.currentUser?.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // ─── Auth ──────────────────────────────────────────────────

  /// Called after Firebase phone OTP verification.
  /// [fullName] is required only for new users (register flow).
  Future<Map<String, dynamic>> phoneVerify({
    required String idToken,
    String? fullName,
    String? lang,
  }) async {
    final res = await _dio.post('/auth/phone-verify', data: {
      'id_token': idToken,
      if (fullName != null) 'full_name': fullName,
      if (lang != null) 'lang': lang,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Update the customer's preferred notification language ('en' | 'ar').
  Future<void> updateLanguage(String userId, String lang) async {
    await _dio.patch('/auth/users/$userId', data: {'lang': lang});
  }

  Future<UserModel> getUser(String userId) async {
    final res = await _dio.get('/auth/users/$userId');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Permanently delete the customer's account from the backend.
  /// [idToken] must be a freshly-minted Firebase ID token; the backend
  /// verifies it and only allows users to delete their own account.
  Future<void> deleteAccount(String userId, String idToken) async {
    await _dio.delete(
      '/auth/users/$userId',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
  }

  /// Staff login via Firebase phone OTP. [idToken] = Firebase ID token.
  Future<bool> verifyAdminPhone(String idToken) async {
    final res = await _dio.post('/auth/admin/phone-verify', data: {
      'id_token': idToken,
    });
    return (res.data as Map<String, dynamic>)['success'] == true;
  }

  // ─── Menu ──────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/menu/categories');
    return (res.data as List<dynamic>)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    bool availableOnly = true,
  }) async {
    final res = await _dio.get(
      '/menu/items',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        'available_only': availableOnly,
      },
    );
    return (res.data as List<dynamic>)
        .map((i) => MenuItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<MenuItem> getMenuItem(String itemId) async {
    final res = await _dio.get('/menu/items/$itemId');
    return MenuItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MenuItem> createMenuItem(Map<String, dynamic> data) async {
    final res = await _dio.post('/menu/items', data: data);
    return MenuItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MenuItem> updateMenuItem(
      String itemId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/menu/items/$itemId', data: data);
    return MenuItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MenuItem> toggleAvailability(String itemId) async {
    final res = await _dio.patch('/menu/items/$itemId/toggle');
    return MenuItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteMenuItem(String itemId) async {
    await _dio.delete('/menu/items/$itemId');
  }

  // ─── Orders ────────────────────────────────────────────────

  Future<Order> placeOrder({
    required String customerId,
    required String customerName,
    required List<CartItem> items,
    required PaymentMethod paymentMethod,
    required String paymentId,
    String? notes,
  }) async {
    final res = await _dio.post('/orders/', data: {
      'customer_id': customerId,
      'customer_name': customerName,
      'items': items.map((i) => i.toOrderItem().toJson()).toList(),
      'payment_method': paymentMethod.toApiString(),
      'payment_id': paymentId,
      if (notes != null) 'notes': notes,
    });
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Order>> getActiveOrders() async {
    final res = await _dio.get('/orders/', queryParameters: {
      'active_only': true,
    });
    return (res.data as List<dynamic>)
        .map((o) => Order.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> getAllOrders({String? status}) async {
    final res = await _dio.get('/orders/', queryParameters: {
      if (status != null) 'status': status,
    });
    return (res.data as List<dynamic>)
        .map((o) => Order.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> getCustomerOrders(String customerId) async {
    final res = await _dio.get('/orders/customer/$customerId');
    return (res.data as List<dynamic>)
        .map((o) => Order.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<Order> getOrder(String orderId) async {
    final res = await _dio.get('/orders/$orderId');
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    final res = await _dio.patch('/orders/$orderId/status', data: {
      'status': status.toApiString(),
    });
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  /// Cancel an order and trigger a full refund. Only works while the
  /// order is still in 'received' status — the backend rejects it once
  /// preparation has started.
  Future<Order> cancelOrder(String orderId) async {
    final res = await _dio.post('/orders/$orderId/cancel');
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Notifications ─────────────────────────────────────────

  Future<void> saveFcmToken({required String userId, required String token}) async {
    await _dio.post('/notifications/token', data: {
      'customer_id': userId,
      'fcm_token': token,
    });
  }
}
