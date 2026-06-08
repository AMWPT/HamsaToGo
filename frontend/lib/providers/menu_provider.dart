import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import 'auth_provider.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCategories();
});

final menuItemsProvider =
    FutureProvider.family<List<MenuItem>, String?>((ref, categoryId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMenuItems(
    categoryId: categoryId,
    availableOnly: true,
  );
});

// Admin: all items including unavailable
final allMenuItemsProvider =
    FutureProvider.family<List<MenuItem>, String?>((ref, categoryId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMenuItems(
    categoryId: categoryId,
    availableOnly: false,
  );
});
