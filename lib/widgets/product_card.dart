import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/error_widget.dart';
import '../core/widgets/success_popup.dart';
import '../models/product.dart';
import '../services/shop_repository.dart';
import 'product_image.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isWishlisted,
  });

  final Product product;
  final bool isWishlisted;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _adding = false;
  bool _changingWishlist = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ShopRepository>();
    final product = widget.product;
    final isLowStock = product.stock > 0 && product.stock <= 3;

    return AnimatedScale(
      scale: _hovered ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? AppColors.gold : AppColors.warmBeige,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.midnight.withValues(
                alpha: _hovered ? 0.13 : 0.05,
              ),
              blurRadius: _hovered ? 16 : 8,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onHover: (hovered) {
            if (_hovered != hovered) setState(() => _hovered = hovered);
          },
          mouseCursor: SystemMouseCursors.click,
          onTap: () => AppRoutes.push<void>(
            context,
            AppRoutes.productDetails,
            arguments: ProductRouteArguments(product: product),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 176,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.warmBeige,
                      child: ProductImage(url: product.imageUrl),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: isLowStock
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.midnight.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Only ${product.stock} left!',
                                style: const TextStyle(
                                  color: AppColors.midnight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : product.category.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.midnight.withValues(
                                  alpha: 0.88,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.category,
                                style: const TextStyle(
                                  color: AppColors.ivory,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: AppColors.ivory,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: AppColors.midnight.withValues(alpha: 0.15),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _changingWishlist
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
                                      setState(() => _changingWishlist = false);
                                    }
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              widget.isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: widget.isWishlisted
                                  ? AppColors.gold
                                  : AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.brand.isNotEmpty)
                            Text(
                              product.brand.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              height: 1.25,
                              color: AppColors.midnight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: AppColors.navy,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product.stock} in stock',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.navy,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ],
                      ),

                      // Price and Add to Cart Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                            ),
                          ),
                          Material(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _adding
                                  ? null
                                  : () async {
                                      setState(() => _adding = true);
                                      try {
                                        if (!await requireSignIn(context)) {
                                          return;
                                        }
                                        await repository.addToCart(product);
                                        if (context.mounted) {
                                          showCartSuccess(context);
                                        }
                                      } catch (error) {
                                        if (context.mounted) {
                                          showErrorMessage(context, error);
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _adding = false);
                                        }
                                      }
                                    },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                child: _adding
                                    ? const SizedBox.square(
                                        dimension: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.ivory,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_shopping_cart_rounded,
                                            size: 15,
                                            color: AppColors.ivory,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Add',
                                            style: TextStyle(
                                              color: AppColors.ivory,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
