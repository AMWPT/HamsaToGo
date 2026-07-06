import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  received,
  inProgress,
  ready,
  pickedUp,
  cancelled;

  static OrderStatus fromString(String s) {
    switch (s) {
      case 'received':
        return received;
      case 'in_progress':
        return inProgress;
      case 'ready':
        return ready;
      case 'picked_up':
        return pickedUp;
      case 'cancelled':
        return cancelled;
      default:
        return received;
    }
  }

  String toApiString() {
    switch (this) {
      case received:
        return 'received';
      case inProgress:
        return 'in_progress';
      case ready:
        return 'ready';
      case pickedUp:
        return 'picked_up';
      case cancelled:
        return 'cancelled';
    }
  }

  String labelEn() {
    switch (this) {
      case received:
        return 'Order Placed';
      case inProgress:
        return 'Order Being Prepared';
      case ready:
        return 'Order Ready for Pickup';
      case pickedUp:
        return 'Order Picked Up';
      case cancelled:
        return 'Order Cancelled';
    }
  }

  String labelAr() {
    switch (this) {
      case received:
        return 'تم تقديم الطلب';
      case inProgress:
        return 'جاري تحضير الطلب';
      case ready:
        return 'الطلب جاهز للاستلام';
      case pickedUp:
        return 'تم استلام الطلب';
      case cancelled:
        return 'تم إلغاء الطلب';
    }
  }

  String label(bool isAr) => isAr ? labelAr() : labelEn();

  // Next valid status for admin
  OrderStatus? get next {
    switch (this) {
      case received:
        return inProgress;
      case inProgress:
        return ready;
      case ready:
        return pickedUp;
      case pickedUp:
        return null;
      case cancelled:
        return null;
    }
  }

  // Only 'received' orders can still be cancelled by the customer.
  bool get isCancellable => this == received;

  int get step {
    switch (this) {
      case received:
        return 0;
      case inProgress:
        return 1;
      case ready:
        return 2;
      case pickedUp:
        return 3;
      case cancelled:
        return -1; // not part of the linear progress timeline
    }
  }
}

enum PaymentMethod {
  mada,
  card, // Visa / Mastercard
  applePay,
  samsungPay;

  String toApiString() {
    switch (this) {
      case mada:
        return 'mada';
      case card:
        return 'card';
      case applePay:
        return 'apple_pay';
      case samsungPay:
        return 'samsung_pay';
    }
  }

  static PaymentMethod? fromString(String? s) {
    switch (s) {
      case 'mada':
        return mada;
      case 'card':
        return card;
      case 'apple_pay':
        return applePay;
      case 'samsung_pay':
        return samsungPay;
      default:
        return null;
    }
  }

  String labelEn() {
    switch (this) {
      case mada:
        return 'mada';
      case card:
        return 'Card';
      case applePay:
        return 'Apple Pay';
      case samsungPay:
        return 'Samsung Pay';
    }
  }

  String labelAr() {
    switch (this) {
      case mada:
        return 'مدى';
      case card:
        return 'بطاقة';
      case applePay:
        return 'Apple Pay';
      case samsungPay:
        return 'Samsung Pay';
    }
  }

  String label(bool isAr) => isAr ? labelAr() : labelEn();
}

class OrderItemModel {
  final String menuItemId;
  final String nameEn;
  final String nameAr;
  final int quantity;
  final double unitPrice;
  final Map<String, String> selectedOptions;
  final String? notes;

  const OrderItemModel({
    required this.menuItemId,
    required this.nameEn,
    required this.nameAr,
    required this.quantity,
    required this.unitPrice,
    required this.selectedOptions,
    this.notes,
  });

  double get subtotal => unitPrice * quantity;

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        menuItemId: json['menu_item_id'] as String,
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['price'] as num).toDouble(),
        selectedOptions: Map<String, String>.from(
            json['customizations'] as Map<dynamic, dynamic>? ?? {}),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name_en': nameEn,
        'name_ar': nameAr,
        'quantity': quantity,
        'price': unitPrice,
        'customizations': selectedOptions,
        if (notes != null) 'notes': notes,
      };
}

class Order {
  final String id;
  final int orderNumber; // sequential, 1-based; 0 = legacy order without one
  final String customerId;
  final List<OrderItemModel> items;
  final double totalPrice;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    this.orderNumber = 0,
    required this.customerId,
    required this.items,
    required this.totalPrice,
    required this.status,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Human-facing order number shown on customer and staff screens.
  /// Legacy orders placed before sequential numbering fall back to
  /// the short Firestore ID.
  String get displayNumber =>
      orderNumber > 0 ? '$orderNumber' : id.substring(0, 8).toUpperCase();

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNumber: (json['order_number'] as num?)?.toInt() ?? 0,
        customerId: json['customer_id'] as String,
        items: (json['items'] as List<dynamic>)
            .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
        totalPrice: (json['total_price'] as num).toDouble(),
        status: OrderStatus.fromString(json['status'] as String),
        paymentMethod: PaymentMethod.fromString(json['payment_method'] as String?),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    return Order(
      id: doc.id,
      orderNumber: (json['order_number'] as num?)?.toInt() ?? 0,
      customerId: json['customer_id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: OrderStatus.fromString(json['status'] as String),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String?),
      notes: json['notes'] as String?,
      createdAt: parseTs(json['created_at']),
      updatedAt: json['updated_at'] != null ? parseTs(json['updated_at']) : null,
    );
  }
}

/// Cart item (before submitting order)
class CartItem {
  final String menuItemId;
  final String nameEn;
  final String nameAr;
  final double unitPrice;
  final int quantity;
  final Map<String, String> selectedOptions;
  final String? notes;

  const CartItem({
    required this.menuItemId,
    required this.nameEn,
    required this.nameAr,
    required this.unitPrice,
    required this.quantity,
    required this.selectedOptions,
    this.notes,
  });

  double get subtotal => unitPrice * quantity;

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;

  CartItem copyWith({int? quantity, Map<String, String>? selectedOptions}) =>
      CartItem(
        menuItemId: menuItemId,
        nameEn: nameEn,
        nameAr: nameAr,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        selectedOptions: selectedOptions ?? this.selectedOptions,
        notes: notes,
      );

  OrderItemModel toOrderItem() => OrderItemModel(
        menuItemId: menuItemId,
        nameEn: nameEn,
        nameAr: nameAr,
        quantity: quantity,
        unitPrice: unitPrice,
        selectedOptions: selectedOptions,
        notes: notes,
      );
}
