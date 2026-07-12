import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../models/menu_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/hamsa_button.dart';
import '../../widgets/hamsa_input.dart';
import '../../widgets/lang_toggle_button.dart';

class MenuManagerScreen extends ConsumerStatefulWidget {
  const MenuManagerScreen({super.key});

  @override
  ConsumerState<MenuManagerScreen> createState() =>
      _MenuManagerScreenState();
}

class _MenuManagerScreenState extends ConsumerState<MenuManagerScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(allMenuItemsProvider(_selectedCategoryId));
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

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
          isAr ? 'إدارة القائمة' : 'Menu Manager',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
        actions: const [LangToggleButton(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          // Category filter
          categoriesAsync.when(
            data: (cats) => SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: isAr ? 'الكل' : 'All',
                    selected: _selectedCategoryId == null,
                    onTap: () =>
                        setState(() => _selectedCategoryId = null),
                  ),
                  ...cats.map(
                    (c) => _FilterChip(
                      label: isAr ? c.nameAr : c.nameEn,
                      selected: _selectedCategoryId == c.id,
                      onTap: () => setState(
                          () => _selectedCategoryId = c.id),
                      onLongPress: () => _confirmDeleteCategory(c, isAr),
                    ),
                  ),
                  _FilterChip(
                    label: isAr ? '+ تصنيف جديد' : '+ New Category',
                    selected: false,
                    onTap: () =>
                        _showAddCategorySheet(context, cats.length),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(height: 48),
          ),

          // Items
          Expanded(
            child: itemsAsync.when(
              data: (items) => RefreshIndicator(
                color: HamsaColors.greenAccent,
                backgroundColor: HamsaColors.bgCard,
                onRefresh: () async => ref.invalidate(
                    allMenuItemsProvider(_selectedCategoryId)),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _MenuItemRow(
                    item: items[i],
                    onToggle: () => _toggle(items[i].id),
                    onEdit: () => _showEditSheet(context, items[i]),
                  )
                      .animate(
                          delay: Duration(milliseconds: i * 50))
                      .fadeIn(duration: 300.ms),
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: HamsaColors.greenAccent),
              ),
              error: (_, __) => Center(
                child: Text(
                  isAr
                      ? 'تعذّر تحميل عناصر القائمة. حاول مرة أخرى.'
                      : 'Could not load menu items. Please try again.',
                  style: const TextStyle(color: HamsaColors.muted),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HamsaColors.greenAccent,
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded, color: HamsaColors.bgDeep),
        label: Text(
          isAr ? 'إضافة عنصر' : 'Add Item',
          style: HamsaText.body(
            size: 13,
            weight: FontWeight.w600,
            color: HamsaColors.bgDeep,
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(String itemId) async {
    final api = ref.read(apiServiceProvider);
    await api.toggleAvailability(itemId);
    _refreshItems();
  }

  /// Invalidate every cached menu list — both the staff one and the
  /// customer-facing one (menuItemsProvider), across all category filters.
  /// Otherwise the customer menu keeps serving its stale cache for the
  /// rest of the session after staff add/edit/remove an item.
  void _refreshItems() {
    ref.invalidate(allMenuItemsProvider);
    ref.invalidate(menuItemsProvider);
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        onSave: (data) async {
          final api = ref.read(apiServiceProvider);
          final created = await api.createMenuItem(data);
          _refreshItems();
          return created;
        },
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category category, bool isAr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HamsaColors.bgCard,
        title: Text(
          isAr
              ? 'حذف تصنيف "${category.nameAr}"؟'
              : 'Delete "${category.nameEn}"?',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
        content: Text(
          isAr
              ? 'لن يتم حذف العناصر الموجودة في هذا التصنيف، لكنها ستظهر فقط ضمن "الكل" حتى يتم نقلها إلى تصنيف آخر.'
              : 'Items in this category will not be deleted, but they will '
                  'only appear under "All" until you move them to another '
                  'category.',
          style: HamsaText.body(size: 14, color: HamsaColors.offWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: HamsaText.body(size: 14, color: HamsaColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isAr ? 'حذف' : 'Delete',
              style: HamsaText.body(size: 14, color: HamsaColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteCategory(category.id);
      if (_selectedCategoryId == category.id) {
        setState(() => _selectedCategoryId = null);
      }
      ref.invalidate(categoriesProvider);
      _refreshItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isAr
                  ? 'تعذّر حذف التصنيف. حاول مرة أخرى.'
                  : 'Could not delete the category. Please try again.')),
        );
      }
    }
  }

  void _showAddCategorySheet(BuildContext context, int existingCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        onSave: (nameEn, nameAr, icon) async {
          final api = ref.read(apiServiceProvider);
          // Append after the existing categories in the chip rows.
          await api.createCategory(
            nameEn: nameEn,
            nameAr: nameAr,
            icon: icon,
            sortOrder: existingCount,
          );
          ref.invalidate(categoriesProvider);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        existing: item,
        onSave: (data) async {
          final api = ref.read(apiServiceProvider);
          final updated = await api.updateMenuItem(item.id, data);
          _refreshItems();
          return updated;
        },
        onDelete: () async {
          final api = ref.read(apiServiceProvider);
          await api.deleteMenuItem(item.id);
          _refreshItems();
        },
      ),
    );
  }
}

// ─── Item Row ────────────────────────────────────────────────
class _MenuItemRow extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _MenuItemRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HamsaColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.available
              ? HamsaColors.border
              : HamsaColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameEn,
                  style: HamsaText.body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: item.available
                        ? HamsaColors.cream
                        : HamsaColors.muted,
                  ),
                ),
                Text(
                  item.nameAr,
                  style: HamsaText.arabic(
                    size: 12,
                    color: HamsaColors.muted,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  'SAR ${item.price.toStringAsFixed(0)}',
                  style: HamsaText.price(size: 15),
                ),
              ],
            ),
          ),

          // Edit
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.edit_outlined,
                  color: HamsaColors.muted, size: 18),
            ),
          ),

          // Availability toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: item.available
                    ? HamsaColors.greenAccent
                    : HamsaColors.bgElevated,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: item.available
                      ? Colors.transparent
                      : HamsaColors.borderStrong,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: item.available
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: HamsaColors.bgDeep,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? HamsaColors.greenAccent
                : HamsaColors.bgElevated,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : HamsaColors.border,
            ),
          ),
          child: Text(
            label,
            style: HamsaText.body(
              size: 13,
              weight: FontWeight.w500,
              color: selected
                  ? HamsaColors.bgDeep
                  : HamsaColors.offWhite,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Category Form Bottom Sheet ───────────────────────────────
class _CategoryFormSheet extends StatefulWidget {
  final Future<void> Function(String nameEn, String nameAr, String? icon)
      onSave;

  const _CategoryFormSheet({required this.onSave});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameEnCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameArCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nameEn = _nameEnCtrl.text.trim();
    final nameAr = _nameArCtrl.text.trim();
    if (nameEn.isEmpty || nameAr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter the category name in both languages')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(nameEn, nameAr, _iconCtrl.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not create the category. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HamsaColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: HamsaColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Category',
              style: HamsaText.heading(size: 20, color: HamsaColors.cream),
            ),
            const SizedBox(height: 4),
            Text(
              'Items can then be assigned to it from the item form.',
              style: HamsaText.body(size: 11, color: HamsaColors.muted),
            ),
            const SizedBox(height: 20),
            HamsaInput(
              label: 'Name (English)',
              controller: _nameEnCtrl,
            ),
            const SizedBox(height: 12),
            HamsaInput(
              label: 'الاسم (عربي)',
              controller: _nameArCtrl,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            HamsaInput(
              label: 'Icon (emoji, optional — e.g. 🥐)',
              controller: _iconCtrl,
            ),
            const SizedBox(height: 20),
            HamsaButton(
              label: 'Add Category',
              isLoading: _saving,
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item Form Bottom Sheet ───────────────────────────────────
class _ItemFormSheet extends ConsumerStatefulWidget {
  final MenuItem? existing;
  final Future<MenuItem> Function(Map<String, dynamic>) onSave;
  final Future<void> Function()? onDelete;

  const _ItemFormSheet({this.existing, required this.onSave, this.onDelete});

  @override
  ConsumerState<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends ConsumerState<_ItemFormSheet> {
  /// Option names as stored on menu items (must match customer screens).
  static const _tempOption = 'Temperature';
  static const _milkOption = 'Milk';

  /// "Coconut Milk (+5 SAR)" → name "Coconut Milk", delta +5.
  /// "Small Cup (-3 SAR)"    → name "Small Cup",    delta -3.
  static final _surchargeSuffix =
      RegExp(r'\s*\(\s*([+-])\s*(\d+(?:\.\d+)?)\s*SAR\)\s*$');

  /// Parse the signed price delta baked into a choice label, if any.
  static double _deltaFromLabel(String label) {
    final m = _surchargeSuffix.firstMatch(label);
    if (m == null) return 0;
    final value = double.tryParse(m.group(2)!) ?? 0;
    return m.group(1) == '-' ? -value : value;
  }

  /// Build the customer-facing choice label with the signed price change
  /// baked in, e.g. "Coconut Milk (+5 SAR)" or "Small Cup (-3 SAR)".
  static String _choiceLabel(String name, double delta) {
    if (delta == 0) return name;
    final v = delta.abs() % 1 == 0
        ? delta.abs().toStringAsFixed(0)
        : delta.abs().toStringAsFixed(2);
    return delta > 0 ? '$name (+$v SAR)' : '$name (-$v SAR)';
  }

  final _nameEnCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _descArCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final List<_CropDraft> _crops = [];
  String? _selectedCategoryId;
  bool _available = true;
  bool _saving = false;

  /// Newly picked photo from the library (uploaded after the item saves);
  /// _removeImage marks an existing photo for removal instead.
  String? _pickedImagePath;
  bool _removeImage = false;

  bool _hasTemperature = false;
  final List<TextEditingController> _tempChoices = [];

  bool _hasMilk = false;
  final List<_ChoiceDraft> _milks = [];

  /// Admin-defined option groups (e.g. Size, Syrup) — editable for every
  /// item regardless of category, each choice with a ± price change.
  final List<_OptionGroupDraft> _customGroups = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameEnCtrl.text = e.nameEn;
      _nameArCtrl.text = e.nameAr;
      _descEnCtrl.text = e.descriptionEn;
      _descArCtrl.text = e.descriptionAr;
      _priceCtrl.text = e.price.toString();
      for (final c in e.crops) {
        _crops.add(_CropDraft(
          nameEn: c.nameEn,
          nameAr: c.nameAr,
          extra: c.priceModifier,
        ));
      }
      _selectedCategoryId = e.categoryId;
      _available = e.available;

      for (final o in e.options) {
        if (o.name == _tempOption) {
          _hasTemperature = true;
          for (final choice in o.choices) {
            _tempChoices.add(TextEditingController(text: choice));
          }
        } else if (o.name == _milkOption) {
          _hasMilk = true;
          for (final choice in o.choices) {
            final extra = o.priceModifiers[choice] ?? _deltaFromLabel(choice);
            _milks.add(_ChoiceDraft(
              name: choice.replaceFirst(_surchargeSuffix, ''),
              extra: extra,
            ));
          }
        } else {
          final group = _OptionGroupDraft(name: o.name, nameAr: o.nameAr);
          for (var i = 0; i < o.choices.length; i++) {
            final choice = o.choices[i];
            final extra = o.priceModifiers[choice] ?? _deltaFromLabel(choice);
            final ar = i < o.choicesAr.length ? o.choicesAr[i] : '';
            group.choices.add(_ChoiceDraft(
              name: choice.replaceFirst(_surchargeSuffix, ''),
              nameAr: ar.replaceFirst(_surchargeSuffix, ''),
              extra: extra,
            ));
          }
          _customGroups.add(group);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameArCtrl.dispose();
    _descEnCtrl.dispose();
    _descArCtrl.dispose();
    _priceCtrl.dispose();
    for (final c in _crops) {
      c.dispose();
    }
    for (final t in _tempChoices) {
      t.dispose();
    }
    for (final m in _milks) {
      m.dispose();
    }
    for (final g in _customGroups) {
      g.dispose();
    }
    super.dispose();
  }

  // ─── Category type detection ───────────────────────────────
  Category? _selectedCategory(List<Category> cats) {
    for (final c in cats) {
      if (c.id == _selectedCategoryId) return c;
    }
    return null;
  }

  bool _isDrink(Category? c) =>
      c != null &&
      (c.nameEn.toLowerCase().contains('drink') || c.nameAr.contains('مشروب'));

  bool _isHotDrink(Category? c) =>
      _isDrink(c) &&
      (c!.nameEn.toLowerCase().contains('hot') || c.nameAr.contains('ساخن'));

  Future<void> _pickImage() async {
    // Downscale on-device so uploads stay small; the backend then
    // normalizes every photo to the same 1200x900 frame.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() {
      _pickedImagePath = picked.path;
      _removeImage = false;
    });
  }

  void _toggleTemperature(bool on) {
    setState(() {
      _hasTemperature = on;
      if (on && _tempChoices.isEmpty) {
        // The cafe's standard temperature choices
        _tempChoices.add(TextEditingController(text: 'Standard'));
        _tempChoices.add(TextEditingController(text: 'Extra Hot'));
      }
    });
  }

  void _toggleMilk(bool on) {
    setState(() {
      _hasMilk = on;
      if (on && _milks.isEmpty) {
        // The cafe's standard milk choices
        _milks.add(_ChoiceDraft(name: 'Full Fat Milk'));
        _milks.add(_ChoiceDraft(name: 'Lactose Free'));
        _milks.add(_ChoiceDraft(name: 'Coconut Milk', extra: 5));
        _milks.add(_ChoiceDraft(name: 'Almond Milk', extra: 5));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cats =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final selectedCat = _selectedCategory(cats);
    final isDrink = _isDrink(selectedCat);
    final isHot = _isHotDrink(selectedCat);

    return Container(
      decoration: const BoxDecoration(
        color: HamsaColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: HamsaColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.existing == null ? 'Add Menu Item' : 'Edit Item',
              style: HamsaText.heading(size: 20, color: HamsaColors.cream),
            ),
            const SizedBox(height: 20),

            // ── Photo ───────────────────────────────────────────
            _buildImageSection(),
            const SizedBox(height: 20),

            HamsaInput(
              label: 'Name (English)',
              controller: _nameEnCtrl,
            ),
            const SizedBox(height: 12),
            HamsaInput(
              label: 'الاسم (عربي)',
              controller: _nameArCtrl,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            HamsaInput(
              label: 'Description (EN)',
              controller: _descEnCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            HamsaInput(
              label: 'الوصف (عربي)',
              controller: _descArCtrl,
              maxLines: 2,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),

            // ── Coffee Crops ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coffee Crops',
                  style: HamsaText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: HamsaColors.cream),
                ),
                GestureDetector(
                  onTap: () => setState(() => _crops.add(_CropDraft())),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: HamsaColors.greenAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Add crop',
                        style: HamsaText.body(
                            size: 13, color: HamsaColors.greenAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Customers must pick one when ordering. Leave empty if not '
              'applicable. Price change is added to the item price — use a '
              'negative value for a discount (e.g. -2).',
              style: HamsaText.body(size: 11, color: HamsaColors.muted),
            ),
            const SizedBox(height: 12),
            ..._crops.asMap().entries.map((entry) {
              final i = entry.key;
              final crop = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: HamsaInput(
                        label: 'Crop (EN)',
                        controller: crop.enCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: HamsaInput(
                        label: 'المحصول (عربي)',
                        controller: crop.arCtrl,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: HamsaInput(
                        label: '± SAR',
                        controller: crop.extraCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: HamsaColors.error, size: 20),
                      onPressed: () => setState(() {
                        _crops.removeAt(i).dispose();
                      }),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // ── Category ────────────────────────────────────────
            Text(
              'Category',
              style: HamsaText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: HamsaColors.cream),
            ),
            const SizedBox(height: 4),
            Text(
              'Drinks can have milk options; hot drinks can also have temperature options.',
              style: HamsaText.body(size: 11, color: HamsaColors.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats
                  .map(
                    (c) => _FilterChip(
                      label: c.nameEn,
                      selected: _selectedCategoryId == c.id,
                      onTap: () =>
                          setState(() => _selectedCategoryId = c.id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            // ── Temperature options (hot drinks only) ───────────
            if (isHot) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Temperature Options',
                    style: HamsaText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: HamsaColors.cream),
                  ),
                  Switch(
                    value: _hasTemperature,
                    onChanged: _toggleTemperature,
                    activeThumbColor: HamsaColors.greenAccent,
                  ),
                ],
              ),
              if (_hasTemperature) ...[
                Text(
                  'Customers must pick one when ordering.',
                  style: HamsaText.body(size: 11, color: HamsaColors.muted),
                ),
                const SizedBox(height: 12),
                ..._tempChoices.asMap().entries.map((entry) {
                  final i = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: HamsaInput(
                            label: 'Temperature choice',
                            controller: entry.value,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: HamsaColors.error, size: 20),
                          onPressed: () => setState(() {
                            _tempChoices.removeAt(i).dispose();
                          }),
                        ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () => setState(
                      () => _tempChoices.add(TextEditingController())),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: HamsaColors.greenAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Add temperature choice',
                        style: HamsaText.body(
                            size: 13, color: HamsaColors.greenAccent),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // ── Milk options (all drinks) ────────────────────────
            if (isDrink) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Milk Options',
                    style: HamsaText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: HamsaColors.cream),
                  ),
                  Switch(
                    value: _hasMilk,
                    onChanged: _toggleMilk,
                    activeThumbColor: HamsaColors.greenAccent,
                  ),
                ],
              ),
              if (_hasMilk) ...[
                Text(
                  'Customers must pick one when ordering. Price change is '
                  'added to the item price — use a negative value for a '
                  'discount (e.g. -2).',
                  style: HamsaText.body(size: 11, color: HamsaColors.muted),
                ),
                const SizedBox(height: 12),
                ..._milks.asMap().entries.map((entry) {
                  final i = entry.key;
                  final milk = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: HamsaInput(
                            label: 'Milk type',
                            controller: milk.nameCtrl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: HamsaInput(
                            label: '± SAR',
                            controller: milk.extraCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: HamsaColors.error, size: 20),
                          onPressed: () => setState(() {
                            _milks.removeAt(i).dispose();
                          }),
                        ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () => setState(() => _milks.add(_ChoiceDraft())),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: HamsaColors.greenAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Add milk type',
                        style: HamsaText.body(
                            size: 13, color: HamsaColors.greenAccent),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // ── Custom options (all items) ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Options',
                  style: HamsaText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: HamsaColors.cream),
                ),
                GestureDetector(
                  onTap: () => setState(() => _customGroups.add(
                      _OptionGroupDraft()..choices.add(_ChoiceDraft()))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: HamsaColors.greenAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Add option group',
                        style: HamsaText.body(
                            size: 13, color: HamsaColors.greenAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Any extra choice the customer must make (e.g. Size, Syrup, '
              'Crop type). Each choice can raise or lower the price — use '
              'a negative value for a discount (e.g. -2).',
              style: HamsaText.body(size: 11, color: HamsaColors.muted),
            ),
            const SizedBox(height: 12),
            ..._customGroups.asMap().entries.map((groupEntry) {
              final gi = groupEntry.key;
              final group = groupEntry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HamsaColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HamsaColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: HamsaInput(
                            label: 'Option name (e.g. Size)',
                            controller: group.nameCtrl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: HamsaInput(
                            label: 'الاسم (عربي)',
                            controller: group.nameArCtrl,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: HamsaColors.error, size: 20),
                          onPressed: () => setState(() {
                            _customGroups.removeAt(gi).dispose();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...group.choices.asMap().entries.map((choiceEntry) {
                      final ci = choiceEntry.key;
                      final choice = choiceEntry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: HamsaInput(
                                label: 'Choice (EN)',
                                controller: choice.nameCtrl,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: HamsaInput(
                                label: 'عربي',
                                controller: choice.arCtrl,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: HamsaInput(
                                label: '± SAR',
                                controller: choice.extraCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: HamsaColors.error,
                                  size: 20),
                              onPressed: () => setState(() {
                                group.choices.removeAt(ci).dispose();
                              }),
                            ),
                          ],
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => setState(
                          () => group.choices.add(_ChoiceDraft())),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: HamsaColors.greenAccent, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Add choice',
                            style: HamsaText.body(
                                size: 13, color: HamsaColors.greenAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            HamsaInput(
              label: 'Price (SAR)',
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available',
                  style: HamsaText.body(
                      size: 14, color: HamsaColors.cream),
                ),
                Switch(
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  activeThumbColor: HamsaColors.greenAccent,
                ),
              ],
            ),

            const SizedBox(height: 20),

            HamsaButton(
              label: widget.existing == null ? 'Add to Menu' : 'Save Changes',
              isLoading: _saving,
              onTap: _saving ? null : () => _save(cats),
            ),

            if (widget.existing != null && widget.onDelete != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _saving ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: HamsaColors.error, size: 18),
                  label: Text(
                    'Remove from Menu',
                    style:
                        HamsaText.body(size: 13, color: HamsaColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final existingUrl = widget.existing?.imageUrl;
    final showExisting =
        _pickedImagePath == null && !_removeImage && existingUrl != null;
    final hasAnyImage = _pickedImagePath != null || showExisting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: HamsaText.body(
              size: 14, weight: FontWeight.w600, color: HamsaColors.cream),
        ),
        const SizedBox(height: 4),
        Text(
          'Shown to customers on the item page. Any photo works — it is '
          'automatically resized to a consistent frame.',
          style: HamsaText.body(size: 11, color: HamsaColors.muted),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _saving ? null : _pickImage,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: HamsaColors.bgElevated,
                child: _pickedImagePath != null
                    ? Image.file(File(_pickedImagePath!), fit: BoxFit.cover)
                    : showExisting
                        ? CachedNetworkImage(
                            imageUrl: existingUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: HamsaColors.muted, size: 40),
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: HamsaColors.muted, size: 40),
                                SizedBox(height: 8),
                                Text('Tap to choose from library',
                                    style: TextStyle(
                                        color: HamsaColors.muted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ),
        if (hasAnyImage)
          Row(
            children: [
              TextButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined,
                    color: HamsaColors.greenAccent, size: 18),
                label: Text('Change',
                    style: HamsaText.body(
                        size: 13, color: HamsaColors.greenAccent)),
              ),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _pickedImagePath = null;
                          _removeImage = existingUrl != null;
                        }),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: HamsaColors.error, size: 18),
                label: Text('Remove',
                    style:
                        HamsaText.body(size: 13, color: HamsaColors.error)),
              ),
            ],
          ),
      ],
    );
  }

  /// Builds the options list from the form state. Sections that are hidden
  /// (wrong category type) or toggled off are simply omitted, which removes
  /// them from the database on save.
  List<Map<String, dynamic>> _buildOptions(List<Category> cats) {
    final cat = _selectedCategory(cats);
    final options = <Map<String, dynamic>>[];

    if (_isHotDrink(cat) && _hasTemperature) {
      final choices = [
        for (final t in _tempChoices)
          if (t.text.trim().isNotEmpty) t.text.trim(),
      ];
      if (choices.isNotEmpty) {
        options.add({
          'name': _tempOption,
          'name_ar': 'درجة الحرارة',
          'choices': choices,
          'required': true,
          'price_modifiers': <String, double>{},
        });
      }
    }

    if (_isDrink(cat) && _hasMilk) {
      final milkOption =
          _optionFromChoices(_milkOption, 'الحليب', _milks);
      if (milkOption != null) options.add(milkOption);
    }

    // Admin-defined option groups (Size, Syrup, …) with ± price changes.
    for (final group in _customGroups) {
      final name = group.nameCtrl.text.trim();
      if (name.isEmpty) continue;
      final built = _optionFromChoices(
          name, group.nameArCtrl.text.trim(), group.choices);
      if (built != null) options.add(built);
    }

    return options;
  }

  /// Builds one option map from choice drafts. The signed price change goes
  /// into the labels so customers see it on the chip, and into
  /// price_modifiers (keyed by the English label) so it's applied to the
  /// price. Arabic labels are display-only and fall back to English.
  Map<String, dynamic>? _optionFromChoices(
      String optionName, String optionNameAr, List<_ChoiceDraft> drafts) {
    final choices = <String>[];
    final choicesAr = <String>[];
    final modifiers = <String, double>{};
    for (final d in drafts) {
      final name = d.nameCtrl.text.trim();
      if (name.isEmpty) continue;
      final nameAr = d.arCtrl.text.trim();
      final delta = double.tryParse(d.extraCtrl.text.trim()) ?? 0;
      final label = _choiceLabel(name, delta);
      choices.add(label);
      choicesAr.add(_choiceLabel(nameAr.isEmpty ? name : nameAr, delta));
      if (delta != 0) modifiers[label] = delta;
    }
    if (choices.isEmpty) return null;
    return {
      'name': optionName,
      'name_ar': optionNameAr,
      'choices': choices,
      'choices_ar': choicesAr,
      'required': true,
      'price_modifiers': modifiers,
    };
  }

  Future<void> _save(List<Category> cats) async {
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isAr
                ? 'الرجاء اختيار تصنيف'
                : 'Please choose a category')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave({
        'name_en': _nameEnCtrl.text.trim(),
        'name_ar': _nameArCtrl.text.trim(),
        'description_en': _descEnCtrl.text.trim(),
        'description_ar': _descArCtrl.text.trim(),
        'crops': [
          for (final c in _crops)
            if (c.enCtrl.text.trim().isNotEmpty ||
                c.arCtrl.text.trim().isNotEmpty)
              {
                'name_en': c.enCtrl.text.trim(),
                'name_ar': c.arCtrl.text.trim(),
                'price_modifier':
                    double.tryParse(c.extraCtrl.text.trim()) ?? 0,
              },
        ],
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'category_id': _selectedCategoryId,
        'available': _available,
        'options': _buildOptions(cats),
      });

      // Photo changes go through their own endpoint — the backend
      // resizes the upload to a consistent frame and hosts it.
      try {
        final api = ref.read(apiServiceProvider);
        if (_pickedImagePath != null) {
          await api.uploadItemImage(saved.id, _pickedImagePath!);
        } else if (_removeImage && widget.existing?.imageUrl != null) {
          await api.removeItemImage(saved.id);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isAr
                    ? 'تم حفظ العنصر لكن تعذّر رفع الصورة. حاول تعديل العنصر مجدداً.'
                    : 'Item saved, but the photo upload failed. Edit the item to retry.')),
          );
        }
      }
      // Refresh again so the new image URL reaches the cached lists.
      ref.invalidate(allMenuItemsProvider);
      ref.invalidate(menuItemsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isAr
                  ? 'تعذّر حفظ العنصر. حاول مرة أخرى.'
                  : 'Could not save the item. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HamsaColors.bgCard,
        title: Text(
          'Remove item?',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
        content: Text(
          '"${widget.existing!.nameEn}" will be permanently removed from the menu.',
          style: HamsaText.body(size: 14, color: HamsaColors.offWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: HamsaText.body(size: 14, color: HamsaColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: HamsaText.body(size: 14, color: HamsaColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final isAr = ref.read(localeProvider).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isAr
                  ? 'تعذّر حذف العنصر. حاول مرة أخرى.'
                  : 'Could not remove the item. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Editable option choice row holder (name + AR + ± SAR) ───
class _ChoiceDraft {
  final TextEditingController nameCtrl;
  final TextEditingController arCtrl;
  final TextEditingController extraCtrl;

  _ChoiceDraft({String name = '', String nameAr = '', double extra = 0})
      : nameCtrl = TextEditingController(text: name),
        arCtrl = TextEditingController(text: nameAr),
        extraCtrl = TextEditingController(
            text: extra == 0
                ? ''
                : extra % 1 == 0
                    ? extra.toStringAsFixed(0)
                    : extra.toString());

  void dispose() {
    nameCtrl.dispose();
    arCtrl.dispose();
    extraCtrl.dispose();
  }
}

// ─── Editable option group holder (e.g. Size with 3 choices) ─
class _OptionGroupDraft {
  final TextEditingController nameCtrl;
  final TextEditingController nameArCtrl;
  final List<_ChoiceDraft> choices = [];

  _OptionGroupDraft({String name = '', String nameAr = ''})
      : nameCtrl = TextEditingController(text: name),
        nameArCtrl = TextEditingController(text: nameAr);

  void dispose() {
    nameCtrl.dispose();
    nameArCtrl.dispose();
    for (final c in choices) {
      c.dispose();
    }
  }
}

// ─── Editable crop row holder ────────────────────────────────
class _CropDraft {
  final TextEditingController enCtrl;
  final TextEditingController arCtrl;
  final TextEditingController extraCtrl;

  _CropDraft({String nameEn = '', String nameAr = '', double extra = 0})
      : enCtrl = TextEditingController(text: nameEn),
        arCtrl = TextEditingController(text: nameAr),
        extraCtrl = TextEditingController(
            text: extra == 0
                ? ''
                : extra % 1 == 0
                    ? extra.toStringAsFixed(0)
                    : extra.toString());

  void dispose() {
    enCtrl.dispose();
    arCtrl.dispose();
    extraCtrl.dispose();
  }
}
