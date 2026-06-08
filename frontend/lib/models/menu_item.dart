class MenuOption {
  final String name;
  final List<String> choices;
  /// Extra SAR added to the base price for a given choice, e.g. {"Coconut Milk (+5 SAR)": 5.0}
  final Map<String, double> priceModifiers;

  const MenuOption({
    required this.name,
    required this.choices,
    this.priceModifiers = const {},
  });

  factory MenuOption.fromJson(Map<String, dynamic> json) => MenuOption(
        name: json['name'] as String,
        choices: List<String>.from(json['choices'] as List),
        priceModifiers: (json['price_modifiers'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
            {},
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'choices': choices,
        'price_modifiers': priceModifiers,
      };
}

class Category {
  final String id;
  final String nameEn;
  final String nameAr;
  final String? icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.icon,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
        icon: json['icon'] as String?,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;
}

class MenuItem {
  final String id;
  final String categoryId;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final double price;
  final bool available;
  final List<MenuOption> options;
  final String? imageUrl;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.price,
    required this.available,
    required this.options,
    this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
        descriptionEn: (json['description_en'] as String?) ?? '',
        descriptionAr: (json['description_ar'] as String?) ?? '',
        price: (json['price'] as num).toDouble(),
        available: json['available'] as bool? ?? true,
        options: (json['options'] as List<dynamic>?)
                ?.map((o) => MenuOption.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [],
        imageUrl: json['image_url'] as String?,
      );

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;
  String description(String locale) =>
      locale == 'ar' ? descriptionAr : descriptionEn;
}
