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
}

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

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLanguage = state.matchedLocation == AppRoutes.language;
      final isAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isAdminLogin = state.matchedLocation == AppRoutes.adminLogin;

      if (authState.isAdmin) {
        if (isAdminLogin || isAuth || isSplash || isLanguage) {
          return AppRoutes.adminDashboard;
        }
      } else if (authState.user != null) {
        if (isAuth || isSplash || isLanguage || isAdminLogin) {
          return AppRoutes.home;
        }
      } else {
        // Not authenticated: kick out of any protected route back to login.
        final isPublic = isSplash || isLanguage || isAuth || isAdminLogin;
        if (!isPublic) {
          return AppRoutes.login;
        }
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
    ],
  );
});
