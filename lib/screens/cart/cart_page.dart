import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../services/shop_repository.dart';
import '../../widgets/product_image.dart';
import '../../widgets/sign_in_prompt.dart';
import '../../widgets/store_message_state.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _scrollController = ScrollController();
  final Map<String, int> _optimisticQuantities = {};
  final Map<String, Future<void>> _quantityWrites = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const SignInPrompt(
        title: 'Sign in to view your bag',
        message: 'Your saved luxury cart will be available after you sign in.',
      );
    }
    final repository = context.read<ShopRepository>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.cartItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StoreMessageState(
            icon: Icons.error_outline,
            title: 'Cart unavailable',
            message: '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) return const LoadingWidget();
        final items = snapshot.data!.docs;
        final visibleItems = items.where((item) {
          final serverQuantity =
              (item.data()['quantity'] as num?)?.toInt() ?? 1;
          return (_optimisticQuantities[item.id] ?? serverQuantity) > 0;
        }).toList();
        if (visibleItems.isEmpty) {
          return const StoreMessageState(
            icon: Icons.shopping_bag_outlined,
            title: 'Your shopping bag is empty',
            message: 'Discover our luxury collection and add a few special pieces.',
          );
        }
        final total = items.fold<double>(
          0,
          (subtotal, item) =>
              subtotal +
              ((item.data()['price'] as num?)?.toDouble() ?? 0) *
                  (_optimisticQuantities[item.id] ??
                      (item.data()['quantity'] as num?)?.toInt() ??
                      1),
        );
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = visibleItems[index];
                        final data = doc.data();
                        final price = (data['price'] as num?)?.toDouble() ?? 0;
                        final serverQuantity =
                            (data['quantity'] as num?)?.toInt() ?? 1;
                        final quantity =
                            _optimisticQuantities[doc.id] ?? serverQuantity;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.warmBeige, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.midnight.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 84,
                                      height: 84,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          color: AppColors.warmBeige,
                                          child: ProductImage(
                                            url: data['imageUrl'] as String? ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] as String? ?? 'Product',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Georgia',
                                              color: AppColors.midnight,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '\$${price.toStringAsFixed(2)} each',
                                            style: const TextStyle(
                                              color: AppColors.navy,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove item',
                                      onPressed: () => _changeQuantity(
                                        context,
                                        repository,
                                        doc.id,
                                        0,
                                        serverQuantity,
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.navy,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1, color: AppColors.warmBeige),
                                ),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Quantity',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.warmBeige,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.gold.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: () => _changeQuantity(
                                              context,
                                              repository,
                                              doc.id,
                                              quantity - 1,
                                              serverQuantity,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(Icons.remove, size: 16, color: AppColors.midnight),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                color: AppColors.midnight,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: () => _changeQuantity(
                                              context,
                                              repository,
                                              doc.id,
                                              quantity + 1,
                                              serverQuantity,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(Icons.add, size: 16, color: AppColors.midnight),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '\$${(price * quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.midnight,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      border: Border.all(color: AppColors.gold, width: 1.2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.midnight.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Subtotal',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.midnight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Boutique Delivery',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              'COMPLIMENTARY',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: AppColors.warmBeige),
                        ),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: AppColors.midnight,
                                ),
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.midnight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _quantityWrites.isNotEmpty
                              ? null
                              : () => _checkout(context, items, total),
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: AppColors.ivory,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_quantityWrites.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Updating your bag...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeQuantity(
    BuildContext context,
    ShopRepository repository,
    String productId,
    int quantity,
    int serverQuantity,
  ) async {
    setState(() => _optimisticQuantities[productId] = quantity);
    final previousWrite = _quantityWrites[productId];
    final write = (previousWrite ?? Future<void>.value()).then<void>(
      (_) => repository.setCartQuantity(productId, quantity),
      onError: (Object _) => repository.setCartQuantity(productId, quantity),
    );
    _quantityWrites[productId] = write;
    try {
      await write;
      if (mounted && identical(_quantityWrites[productId], write)) {
        setState(() => _optimisticQuantities.remove(productId));
      }
    } catch (error) {
      if (mounted && identical(_quantityWrites[productId], write)) {
        setState(() => _optimisticQuantities[productId] = serverQuantity);
      }
      if (context.mounted) showErrorMessage(context, error);
    } finally {
      if (identical(_quantityWrites[productId], write)) {
        _quantityWrites.remove(productId);
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _checkout(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
    double subtotal,
  ) async {
    while (_quantityWrites.isNotEmpty) {
      try {
        await Future.wait(List<Future<void>>.of(_quantityWrites.values));
      } catch (_) {
        return;
      }
    }
    if (!context.mounted) return;
    await AppRoutes.push<void>(
      context,
      AppRoutes.checkout,
      arguments: CheckoutRouteArguments(items: items, subtotal: subtotal),
    );
  }
}
