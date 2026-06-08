enum OrderStatus {
  received,
  inProgress,
  ready,
  pickedUp;

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
    }
  }

  String labelEn() {
    switch (this) {
      case received:
        return 'Order Received';
      case inProgress:
        return 'In Progress';
      case ready:
        return 'Ready for Pickup';
      case pickedUp:
        return 'Picked Up';
    }
  }

  String labelAr() {
    switch (this) {
      case received:
        return 'تم استلام الطلب';
      case inProgress:
        return 'جاري التحضير';
      case ready:
        return 'جاهز للاستلام';
      case pickedUp:
        return 'تم الاستلام';
    }
  }

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
    }
  }

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
    }
  }
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
        unitPrice: (json['unit_price'] as num).toDouble(),
        selectedOptions: Map<String, String>.from(
            json['selected_options'] as Map<dynamic, dynamic>? ?? {}),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name_en': nameEn,
        'name_ar': nameAr,
        'quantity': quantity,
        'unit_price': unitPrice,
        'selected_options': selectedOptions,
        if (notes != null) 'notes': notes,
      };
}

class Order {
  final String id;
  final String customerId;
  final List<OrderItemModel> items;
  final double totalPrice;
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        items: (json['items'] as List<dynamic>)
            .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
        totalPrice: (json['total_price'] as num).toDouble(),
        status: OrderStatus.fromString(json['status'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );
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
