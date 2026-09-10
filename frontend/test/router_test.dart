// Guards the signed-out browsing rules introduced for App Store guideline
// 5.1.1(v): the menu, item details and the cart must stay reachable without an
// account, while order history and the staff area must not — and the
// return-after-sign-in hop must never leave the app.
import 'package:flutter_test/flutter_test.dart';
import 'package:hamsa_flutter/core/router.dart';

void main() {
  group('isPublicRoute', () {
    test('browsing without an account is allowed', () {
      for (final path in [
        AppRoutes.splash,
        AppRoutes.language,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.adminLogin,
        AppRoutes.legal,
        AppRoutes.home,
        AppRoutes.cart,
        '/item/abc123',
      ]) {
        expect(isPublicRoute(path), isTrue, reason: '$path should be public');
      }
    });

    test('account-based and staff screens still require sign-in', () {
      for (final path in [
        AppRoutes.myOrders,
        '/orders/xyz789',
        AppRoutes.adminDashboard,
        AppRoutes.menuManager,
        AppRoutes.reports,
        AppRoutes.history,
        '/admin/orders/abc',
      ]) {
        expect(isPublicRoute(path), isFalse, reason: '$path should be gated');
      }
    });

    test('the login destination is itself public, so gating cannot loop', () {
      // A gated path sends the user to login; login must be public or the
      // redirect would fire again forever.
      final target = loginWithReturn(AppRoutes.myOrders);
      final path = Uri.parse(target).path;
      expect(isPublicRoute(path), isTrue);
    });
  });

  group('isStaffRoute', () {
    test('covers every screen in the staff area', () {
      for (final path in [
        AppRoutes.adminDashboard,
        AppRoutes.menuManager,
        AppRoutes.history,
        AppRoutes.reports,
        '/admin/orders/abc123',
      ]) {
        expect(isStaffRoute(path), isTrue, reason: '$path is staff-only');
      }
    });

    test('excludes the staff login itself, so signing in cannot loop', () {
      expect(isStaffRoute(AppRoutes.adminLogin), isFalse);
      expect(isPublicRoute(AppRoutes.adminLogin), isTrue);
    });

    test('does not catch customer screens', () {
      for (final path in [
        AppRoutes.home,
        AppRoutes.cart,
        AppRoutes.myOrders,
        '/orders/abc123',
        '/item/abc123',
      ]) {
        expect(isStaffRoute(path), isFalse, reason: '$path is not staff-only');
      }
    });
  });

  group('loginWithReturn', () {
    test('carries the originating path as an encoded query parameter', () {
      final target = loginWithReturn(AppRoutes.cart);
      expect(Uri.parse(target).path, AppRoutes.login);
      expect(Uri.parse(target).queryParameters['from'], AppRoutes.cart);
    });

    test('round-trips a path containing an id', () {
      final target = loginWithReturn('/orders/abc123');
      expect(Uri.parse(target).queryParameters['from'], '/orders/abc123');
    });
  });

  group('sanitizeReturnTarget', () {
    test('accepts in-app absolute paths', () {
      expect(sanitizeReturnTarget('/cart'), '/cart');
      expect(sanitizeReturnTarget('/orders/abc'), '/orders/abc');
    });

    test('ignores an absent or empty value', () {
      expect(sanitizeReturnTarget(null), isNull);
      expect(sanitizeReturnTarget(''), isNull);
    });

    test('refuses to send the user off-app after sign-in', () {
      expect(sanitizeReturnTarget('https://evil.example/phish'), isNull);
      expect(sanitizeReturnTarget('//evil.example/phish'), isNull);
      expect(sanitizeReturnTarget('http://evil.example'), isNull);
      expect(sanitizeReturnTarget('cart'), isNull); // relative, not in-app
    });
  });
}
