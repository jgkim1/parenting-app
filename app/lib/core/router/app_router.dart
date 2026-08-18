import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/domain/ad.dart';
import '../../features/admin/presentation/admin_ad_form_screen.dart';
import '../../features/admin/presentation/admin_ad_list_screen.dart';
import '../../features/admin/presentation/admin_article_form_screen.dart';
import '../../features/admin/presentation/admin_article_list_screen.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/admin/presentation/admin_product_form_screen.dart';
import '../../features/admin/presentation/admin_product_list_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/articles/presentation/article_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/orders/presentation/checkout_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/order_list_screen.dart';
import '../../features/community/domain/post_detail.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/community/presentation/post_form_screen.dart';

// authControllerProvider의 상태 변화를 go_router의 refreshListenable로 전달해,
// 로그인/로그아웃이 일어나면 redirect가 즉시 재평가되도록 연결한다.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (authState is AuthLoading) return null;

      final isAuthenticated = authState is AuthAuthenticated;
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';

      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      if (isAdminRoute && (!isAuthenticated || authState.user.role != 'ADMIN')) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/articles/:id',
        builder: (context, state) =>
            ArticleDetailScreen(articleId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (context, state) => const OrderListScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/community/new', builder: (context, state) => const PostFormScreen()),
      GoRoute(
        path: '/community/:id',
        builder: (context, state) => PostDetailScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/community/:id/edit',
        builder: (context, state) =>
            PostFormScreen(editingPost: state.extra as PostDetail?),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
      GoRoute(path: '/admin/products', builder: (context, state) => const AdminProductListScreen()),
      GoRoute(
        path: '/admin/products/new',
        builder: (context, state) => const AdminProductFormScreen(),
      ),
      GoRoute(
        path: '/admin/products/:id/edit',
        builder: (context, state) =>
            AdminProductFormScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/articles', builder: (context, state) => const AdminArticleListScreen()),
      GoRoute(
        path: '/admin/articles/new',
        builder: (context, state) => const AdminArticleFormScreen(),
      ),
      GoRoute(
        path: '/admin/articles/:id/edit',
        builder: (context, state) =>
            AdminArticleFormScreen(articleId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/ads', builder: (context, state) => const AdminAdListScreen()),
      GoRoute(path: '/admin/ads/new', builder: (context, state) => const AdminAdFormScreen()),
      GoRoute(
        path: '/admin/ads/:id/edit',
        builder: (context, state) => AdminAdFormScreen(editing: state.extra as Ad?),
      ),
    ],
  );
});
