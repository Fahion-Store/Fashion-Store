import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';

// Screen imports
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/product_listing_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash/splash_screen.dart';

class AppRoutes {
  // ── Route name constants ───────────────────────────────────────────────────
  static const String splash         = '/splash';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String home           = '/home';
  static const String productListing = '/products';
  static const String productDetail  = '/products/:id';
  static const String cart           = '/cart';
  static const String checkout       = '/checkout';
  static const String profile        = '/profile';
  static const String wishlist       = '/wishlist';

  // ── Router config ──────────────────────────────────────────────────────────
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final bool loggedIn = userProvider.isAuthenticated;
      
      final bool isAuthRoute = state.matchedLocation == login || state.matchedLocation == register;
      final bool isSplashRoute = state.matchedLocation == splash;

      // If logged in and trying to access auth pages, go home
      if (loggedIn && isAuthRoute) return home;
      
      // If NOT logged in and trying to access protected pages (not splash or auth), go to login
      if (!loggedIn && !isAuthRoute && !isSplashRoute) return login;

      return null;
    },
    routes: [
      // ── Splash route ──────────────────────────────────────────────────────
      GoRoute(
        path: splash,
        name: 'splash',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          ThemeSafePage(builder: (context) => const SplashScreen()),
        ),
      ),

      // ── Auth routes (no bottom nav) ──────────────────────────────────────
      GoRoute(
        path: login,
        name: 'login',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          ThemeSafePage(builder: (context) => const LoginScreen()),
        ),
      ),
      GoRoute(
        path: register,
        name: 'register',
        pageBuilder: (context, state) => _slideTransition(
          state,
          ThemeSafePage(builder: (context) => const RegisterScreen()),
        ),
      ),

      // ── Main app shell (has bottom navigation bar) ───────────────────────
      ShellRoute(
        builder: (context, state, child) => ThemeSafePage(
          builder: (context) => MainShell(child: child),
        ),
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              ThemeSafePage(builder: (context) => const HomeScreen()),
            ),
          ),
          GoRoute(
            path: productListing,
            name: 'productListing',
            pageBuilder: (context, state) {
              final category = state.uri.queryParameters['category'] ?? 'All';
              return _slideTransition(
                state,
                ThemeSafePage(
                  builder: (context) => ProductListingScreen(category: category),
                ),
              );
            },
            routes: [
              GoRoute(
                path: ':id',
                name: 'productDetail',
                pageBuilder: (context, state) {
                  final productId = state.pathParameters['id'] ?? '';
                  return _slideTransition(
                    state,
                    ThemeSafePage(
                      builder: (context) => ProductDetailScreen(productId: productId),
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: cart,
            name: 'cart',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              ThemeSafePage(builder: (context) => const CartScreen()),
            ),
          ),
          GoRoute(
            path: profile,
            name: 'profile',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              ThemeSafePage(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),

      // ── Checkout (full screen, no bottom nav) ────────────────────────────
      GoRoute(
        path: checkout,
        name: 'checkout',
        pageBuilder: (context, state) => _slideTransition(
          state,
          ThemeSafePage(builder: (context) => const CheckoutScreen()),
        ),
      ),
      GoRoute(
        path: wishlist,
        name: 'wishlist',
        pageBuilder: (context, state) => _slideTransition(
          state,
          ThemeSafePage(builder: (context) => const WishlistScreen()),
        ),
      ),
    ],

    // ── Error page ──────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.error}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );

  // ── Page transition helpers ────────────────────────────────────────────────
  static CustomTransitionPage _fadeTransition(
      GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static CustomTransitionPage _slideTransition(
      GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class ThemeSafePage extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  const ThemeSafePage({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return builder(context);
  }
}