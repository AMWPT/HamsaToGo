import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

final _fs = FirebaseFirestore.instance;

/// Real-time cafe "busy" flag. Staff flip it from the dashboard; customers
/// and staff both listen so the "we're busy, can't take orders" banner and
/// the disabled checkout button react instantly.
///
/// Missing doc → `false` (open). On a stream error the AsyncValue is in its
/// error state; consumers read it as `.valueOrNull ?? false` so a transient
/// read failure never wrongly blocks ordering.
///
/// The settings doc is publicly readable (see firestore.rules), so signed-out
/// visitors browsing the menu see the busy banner too — they'd otherwise fill
/// a cart before discovering ordering is paused. autoDispose + a watch on the
/// signed-in identity so the listener is rebuilt fresh whenever auth changes.
final cafeBusyProvider = StreamProvider.autoDispose<bool>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  ref.watch(authProvider.select((s) => s.isAdmin));

  return _fs
      .collection('settings')
      .doc('status')
      .snapshots()
      .map((snap) => (snap.data()?['is_busy'] as bool?) ?? false);
});
