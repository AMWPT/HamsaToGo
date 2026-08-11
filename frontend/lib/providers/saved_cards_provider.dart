import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_card.dart';
import 'auth_provider.dart';

/// The signed-in customer's saved cards. Invalidate after an order placed
/// with "save card" or after deleting a card so the list refreshes.
final savedCardsProvider =
    FutureProvider.autoDispose<List<SavedCard>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return const [];
  return ref.watch(apiServiceProvider).getSavedCards();
});
