class MenuOption {
  /// Canonical (English) name — also the key stored in order customizations.
  final String name;

  /// Arabic display name; falls back to [name] when empty.
  final String nameAr;

  final List<String> choices;

  /// Arabic display labels, parallel to [choices]; entries fall back to the
  /// English label when missing/empty.
  final List<String> choicesAr;

  /// Signed SAR added to the base price for a given choice (negatives
  /// discount), e.g. {"Coconut Milk (+5 SAR)": 5.0}
  final Map<String, double> priceModifiers;

  const MenuOption({
    required this.name,
    this.nameAr = '',
    required this.choices,
    this.choicesAr = const [],
    this.priceModifiers = const {},
  });

  factory MenuOption.fromJson(Map<String, dynamic> json) => MenuOption(
        name: json['name'] as String,
        nameAr: (json['name_ar'] as String?) ?? '',
        choices: List<String>.from(json['choices'] as List),
        choicesAr: (json['choices_ar'] as List<dynamic>?)
                ?.map((c) => c as String)
                .toList() ??
            const [],
        priceModifiers: (json['price_modifiers'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
            {},
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_ar': nameAr,
        'choices': choices,
        'choices_ar': choicesAr,
        'price_modifiers': priceModifiers,
      };

  String displayName(String locale) =>
      locale == 'ar' && nameAr.isNotEmpty ? nameAr : name;

  /// Display label for choices[i] in the given locale, falling back to the
  /// English label when no Arabic translation exists.
  String displayChoice(int i, String locale) {
    if (locale == 'ar' && i < choicesAr.length && choicesAr[i].isNotEmpty) {
      return choicesAr[i];
    }
    return choices[i];
  }
}

class Crop {
  final String nameEn;
  final String nameAr;

  /// Signed SAR added to the item price when this crop is chosen.
  final double priceModifier;

  const Crop({
    required this.nameEn,
    required this.nameAr,
    this.priceModifier = 0,
  });

  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
        nameEn: (json['name_en'] as String?) ?? '',
        nameAr: (json['name_ar'] as String?) ?? '',
        priceModifier: (json['price_modifier'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name_en': nameEn,
        'name_ar': nameAr,
        'price_modifier': priceModifier,
      };

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;

  @override
  bool operator ==(Object other) =>
      other is Crop && other.nameEn == nameEn && other.nameAr == nameAr;

  @override
  int get hashCode => Object.hash(nameEn, nameAr);
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
  final List<Crop> crops;
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
    this.crops = const [],
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
        crops: (json['crops'] as List<dynamic>?)
                ?.map((c) => Crop.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
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
