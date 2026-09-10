import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/language/language_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/item_detail/item_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/orders/my_orders_screen.dart';
import '../screens/orders/order_status_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_order_detail_screen.dart';
import '../screens/admin/menu_manager_screen.dart';
import '../screens/admin/history_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/legal/legal_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const itemDetail = '/item/:id';
  static const cart = '/cart';
  static const myOrders = '/orders';
  static const orderStatus = '/orders/:id';
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin/dashboard';
  static const adminOrderDetail = '/admin/orders/:id';
  static const menuManager = '/admin/menu';
  static const history = '/admin/history';
  static const reports = '/admin/reports';
  static const legal = '/legal';
}

/// Screens a signed-out visitor may use.
///
/// Browsing the menu, opening an item and filling a cart are deliberately
/// public: App Store guideline 5.1.1(v) only permits gating features that are
/// genuinely account-based, so sign-in is demanded at checkout and for order
/// history — not at the front door.
bool isPublicRoute(String path) {
  const public = {
    AppRoutes.splash,
    AppRoutes.language,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.adminLogin,
    AppRoutes.legal,
    AppRoutes.home,
    AppRoutes.cart,
  };
  return public.contains(path) || path.startsWith('/item/');
}

/// The staff-only area (everything under /admin except the staff login).
///
/// Every backing endpoint enforces staff access server-side, so this is not
/// the security boundary — it just stops anyone who isn't signed in as staff
/// from rendering the screens at all, whether they're a signed-out visitor or
/// a signed-in customer who typed the path.
bool isStaffRoute(String path) =>
    path.startsWith('/admin') && path != AppRoutes.adminLogin;

/// The login route, carrying the path to come back to once signed in.
String loginWithReturn(String path) =>
    '${AppRoutes.login}?from=${Uri.encodeComponent(path)}';

/// Validates a `?from=` value before we navigate to it. Only in-app absolute
/// paths are allowed: an absolute URL (`https://…`) or a protocol-relative one
/// (`//host`) is rejected so a crafted link can never bounce a user off-app
/// after sign-in.
String? sanitizeReturnTarget(String? from) {
  if (from == null || from.isEmpty) return null;
  if (!from.startsWith('/') || from.startsWith('//')) return null;
  return from;
}

/// Where to send a user immediately after signing in: back to the screen that
/// sent them to login, when it's a safe in-app path — otherwise home.
String? returnTargetOf(GoRouterState state) =>
    sanitizeReturnTarget(state.uri.queryParameters['from']);

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      if (isLoading) return null; // let splash handle it

      final path = state.matchedLocation;
      final isSplash = path == AppRoutes.splash;
      final isLanguage = path == AppRoutes.language;
      final isAuth = path == AppRoutes.login || path == AppRoutes.register;
      final isAdminLogin = path == AppRoutes.adminLogin;
      final isLegal = path == AppRoutes.legal;

      if (isLegal) return null; // policies are public, reachable from anywhere

      if (authState.isAdmin) {
        if (isAdminLogin || isAuth || isSplash || isLanguage) {
          return AppRoutes.adminDashboard;
        }
      } else if (authState.user != null) {
        if (isAuth || isSplash || isLanguage || isAdminLogin) {
          // Signed in from a screen that needed an account — return to it.
          return returnTargetOf(state) ?? AppRoutes.home;
        }
        // A customer account is not a staff account — send them back to the
        // menu rather than rendering the staff area.
        if (isStaffRoute(path)) return AppRoutes.home;
      } else {
        // Signed out: browsing is public (menu, item details, cart).
        if (isPublicRoute(path)) return null;
        // The staff area goes to the staff login; account-based customer
        // screens go to the customer login, remembering where to return.
        if (isStaffRoute(path)) return AppRoutes.adminLogin;
        return loginWithReturn(path);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (_, __) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.itemDetail,
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ItemDetailScreen(
            itemId: itemId,
            heroTag: extra?['heroTag'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.myOrders,
        builder: (_, __) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderStatus,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return OrderStatusScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminOrderDetail,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return AdminOrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.menuManager,
        builder: (_, __) => const MenuManagerScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (_, __) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.legal,
        builder: (_, __) => const LegalScreen(),
      ),
    ],
  );
});
