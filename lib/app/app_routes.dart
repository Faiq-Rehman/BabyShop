import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../screens/account/account_page.dart';
import '../screens/auth/auth_page.dart';
import '../screens/cart/cart_page.dart';
import '../screens/categories/category_page.dart';
import '../screens/checkout/checkout_page.dart';
import '../screens/home/shop_page.dart';
import '../screens/orders/order_tracking_page.dart';
import '../screens/orders/orders_page.dart';
import '../screens/products/product_detail_page.dart';
import '../screens/support/support_page.dart';
import '../screens/wishlist/wishlist_page.dart';
import '../widgets/store_message_state.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const categories = '/categories';
  static const cart = '/cart';
  static const account = '/account';
  static const auth = '/auth';
  static const productDetails = '/product-details';
  static const checkout = '/checkout';
  static const wishlist = '/wishlist';
  static const orders = '/orders';
  static const orderTracking = '/order-tracking';
  static const support = '/support';

  static final Set<String> _activePushes = {};

  static Future<T?> push<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) async {
    final navigator = Navigator.of(context);
    final key = '${identityHashCode(navigator)}:$route';
    if (!_activePushes.add(key)) return null;
    try {
      return await navigator.pushNamed<T>(route, arguments: arguments);
    } finally {
      _activePushes.remove(key);
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case home:
        page = const ShopPage();
      case categories:
        return MaterialPageRoute<String>(
          settings: settings,
          builder: (context) => CategoryPage(
            selected: '',
            onSelected: (category) => Navigator.of(context).pop<String>(category),
          ),
        );
      case cart:
        page = const CartPage();
      case account:
        page = AccountPage(user: FirebaseAuth.instance.currentUser);
      case auth:
        page = const AuthPage();
      case productDetails:
        final arguments = settings.arguments;
        if (arguments is! ProductRouteArguments) {
          return _invalidRoute(settings, 'Product information is missing.');
        }
        page = ProductPage(product: arguments.product);
      case checkout:
        final arguments = settings.arguments;
        if (arguments is! CheckoutRouteArguments) {
          return _invalidRoute(settings, 'Checkout information is missing.');
        }
        page = CheckoutPage(
          items: arguments.items,
          subtotal: arguments.subtotal,
        );
      case wishlist:
        page = const WishlistPage();
      case orders:
        page = const OrdersPage();
      case orderTracking:
        final arguments = settings.arguments;
        if (arguments is! OrderTrackingRouteArguments) {
          return _invalidRoute(settings, 'Order information is missing.');
        }
        page = OrderTrackingPage(
          orderId: arguments.orderId,
          order: arguments.order,
        );
      case support:
        page = const SupportPage();
      default:
        return _invalidRoute(settings, 'This destination is not available.');
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => page,
    );
  }

  static Route<dynamic> _invalidRoute(RouteSettings settings, String message) =>
      MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Page unavailable')),
          body: StoreMessageState(
            icon: Icons.route_outlined,
            title: 'Unable to open this page',
            message: message,
          ),
        ),
      );
}

class ProductRouteArguments {
  const ProductRouteArguments({required this.product});

  final Product product;
}

class CheckoutRouteArguments {
  const CheckoutRouteArguments({required this.items, required this.subtotal});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;
  final double subtotal;
}

class OrderTrackingRouteArguments {
  const OrderTrackingRouteArguments({required this.orderId, required this.order});

  final String orderId;
  final Map<String, dynamic> order;
}

Future<void> openAuth(BuildContext context) async {
  await AppRoutes.push<void>(context, AppRoutes.auth);
}

Future<bool> requireSignIn(BuildContext context) async {
  if (FirebaseAuth.instance.currentUser != null) return true;
  await openAuth(context);
  return FirebaseAuth.instance.currentUser != null;
}

Future<void> openWishlist(BuildContext context) async {
  if (!await requireSignIn(context) || !context.mounted) return;
  await AppRoutes.push<void>(context, AppRoutes.wishlist);
}
