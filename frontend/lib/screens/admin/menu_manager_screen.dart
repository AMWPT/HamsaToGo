import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/menu_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/hamsa_button.dart';
import '../../widgets/hamsa_input.dart';

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
    final itemsAsync =
        ref.watch(allMenuItemsProvider(_selectedCategoryId));

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
          'Menu Manager',
          style: HamsaText.heading(size: 18, color: HamsaColors.cream),
        ),
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
                    label: 'All',
                    selected: _selectedCategoryId == null,
                    onTap: () =>
                        setState(() => _selectedCategoryId = null),
                  ),
                  ...cats.map(
                    (c) => _FilterChip(
                      label: c.nameEn,
                      selected: _selectedCategoryId == c.id,
                      onTap: () => setState(
                          () => _selectedCategoryId = c.id),
                    ),
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
              error: (_, __) => const Center(
                child: Text('Error', style: TextStyle(color: HamsaColors.muted)),
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
          'Add Item',
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
    ref.invalidate(allMenuItemsProvider(_selectedCategoryId));
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(
        onSave: (data) async {
          final api = ref.read(apiServiceProvider);
          await api.createMenuItem(data);
          ref.invalidate(allMenuItemsProvider(null));
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
          await api.updateMenuItem(item.id, data);
          ref.invalidate(allMenuItemsProvider(null));
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

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
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

// ─── Item Form Bottom Sheet ───────────────────────────────────
class _ItemFormSheet extends StatefulWidget {
  final MenuItem? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _ItemFormSheet({this.existing, required this.onSave});

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _nameEnCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _descArCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final List<_CropDraft> _crops = [];
  final _catIdCtrl = TextEditingController();
  bool _available = true;
  bool _saving = false;

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
        _crops.add(_CropDraft(nameEn: c.nameEn, nameAr: c.nameAr));
      }
      _catIdCtrl.text = e.categoryId;
      _available = e.available;
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
    _catIdCtrl.dispose();
    super.dispose();
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
              'Customers must pick one when ordering. Leave empty if not applicable.',
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
                      child: HamsaInput(
                        label: 'Crop (EN)',
                        controller: crop.enCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HamsaInput(
                        label: 'المحصول (عربي)',
                        controller: crop.arCtrl,
                        textDirection: TextDirection.rtl,
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
            Row(
              children: [
                Expanded(
                  child: HamsaInput(
                    label: 'Price (SAR)',
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HamsaInput(
                    label: 'Category ID',
                    controller: _catIdCtrl,
                  ),
                ),
              ],
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
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave({
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
              },
        ],
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'category_id': _catIdCtrl.text.trim(),
        'available': _available,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Editable crop row holder ────────────────────────────────
class _CropDraft {
  final TextEditingController enCtrl;
  final TextEditingController arCtrl;

  _CropDraft({String nameEn = '', String nameAr = ''})
      : enCtrl = TextEditingController(text: nameEn),
        arCtrl = TextEditingController(text: nameAr);

  void dispose() {
    enCtrl.dispose();
    arCtrl.dispose();
  }
}
