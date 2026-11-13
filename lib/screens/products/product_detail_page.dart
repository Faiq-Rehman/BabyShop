import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/success_popup.dart';
import '../../models/product.dart';
import '../../services/shop_repository.dart';
import '../../widgets/product_image.dart';
import '../../widgets/store_message_state.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({required this.product, super.key});

  final Product product;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int _quantity = 1;
  bool _adding = false;
  bool _changingWishlist = false;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ShopRepository>();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repository.product(widget.product.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product details')),
            body: StoreMessageState(
              icon: Icons.error_outline,
              title: 'Product unavailable',
              message: '${snapshot.error}',
            ),
          );
        }
        if (!snapshot.hasData) return const LoadingWidget();
        if (!snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product details')),
            body: const StoreMessageState(
              icon: Icons.inventory_2_outlined,
              title: 'Product no longer available',
              message: 'This product may have been removed from the store.',
            ),
          );
        }
        final product = Product.fromFirestore(snapshot.data!);
        if (!product.isActive) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product details')),
            body: const StoreMessageState(
              icon: Icons.inventory_2_outlined,
              title: 'Product no longer available',
              message: 'This product is not currently available for purchase.',
            ),
          );
        }
        final displayQuantity = product.stock > 0
            ? _quantity.clamp(1, product.stock).toInt()
            : 1;
        return Scaffold(
          appBar: AppBar(title: const Text('Product details')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final image = ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: isWide ? 0.96 : 1.12,
                  child: ColoredBox(
                    color: AppColors.warmBeige,
                    child: ProductImage(url: product.imageUrl),
                  ),
                ),
              );
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 25,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.midnight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseAuth.instance.currentUser == null
                            ? null
                            : repository.wishlistItem(product.id),
                        builder: (context, wishlistSnapshot) {
                          final selected =
                              wishlistSnapshot.data?.exists ?? false;
                          return IconButton.filledTonal(
                            tooltip: selected
                                ? 'Remove from wishlist'
                                : 'Add to wishlist',
                            onPressed: _changingWishlist
                                ? null
                                : () async {
                                    if (!await requireSignIn(context)) return;
                                    setState(() => _changingWishlist = true);
                                    try {
                                      await repository.toggleWishlist(product);
                                    } catch (error) {
                                      if (context.mounted) {
                                        showErrorMessage(context, error);
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(
                                          () => _changingWishlist = false,
                                        );
                                      }
                                    }
                                  },
                            icon: Icon(
                              selected ? Icons.favorite : Icons.favorite_border,
                              color: selected ? AppColors.gold : AppColors.navy,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (product.brand.isNotEmpty) ...[
                    Text(
                      product.brand.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      _ProductDetailTag(
                        icon: Icons.grid_view_rounded,
                        label: product.category,
                      ),
                      _ProductDetailTag(
                        icon: product.stock > 0
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        label: product.stock > 0
                            ? '${product.stock} in stock'
                            : 'Out of stock',
                        color: product.stock > 0
                            ? AppColors.midnight
                            : AppColors.navy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.warmBeige),
                  const SizedBox(height: 16),
                  Text(
                    product.description.isEmpty
                        ? 'A thoughtful luxury essential for your little one.'
                        : product.description,
                    style: const TextStyle(height: 1.6, color: AppColors.navy, fontSize: 13.5),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Quantity',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.midnight,
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
                              onTap: _quantity <= 1
                                  ? null
                                  : () => setState(
                                      () => _quantity = displayQuantity - 1,
                                    ),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(Icons.remove, size: 16, color: AppColors.midnight),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$displayQuantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.midnight,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: displayQuantity >= product.stock
                                  ? null
                                  : () => setState(
                                      () => _quantity = displayQuantity + 1,
                                    ),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(Icons.add, size: 16, color: AppColors.midnight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: product.stock == 0 || _adding
                        ? null
                        : () async {
                            setState(() => _adding = true);
                            try {
                              if (!await requireSignIn(context)) return;
                              await repository.addToCart(
                                product,
                                quantity: displayQuantity,
                              );
                              if (context.mounted) showCartSuccess(context);
                            } catch (error) {
                              if (context.mounted) {
                                showErrorMessage(context, error);
                              }
                            } finally {
                              if (mounted) setState(() => _adding = false);
                            }
                          },
                    icon: _adding
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ivory,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(_adding ? 'Adding...' : 'Add to cart'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ],
              );
              return SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 28 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: image),
                              const SizedBox(width: 34),
                              Expanded(flex: 5, child: details),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              image,
                              const SizedBox(height: 22),
                              details,
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductDetailTag extends StatelessWidget {
  const _ProductDetailTag({
    required this.icon,
    required this.label,
    this.color = AppColors.midnight,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.warmBeige,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color == AppColors.midnight ? AppColors.gold : color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
