import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../services/shop_repository.dart';
import '../../widgets/product_image.dart';
import '../../widgets/store_message_state.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ivory,
    appBar: AppBar(
      title: const Text(
        'Wishlist',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<ShopRepository>().wishlistItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StoreMessageState(
            icon: Icons.error_outline,
            title: 'Wishlist unavailable',
            message: '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) return const LoadingWidget();
        final items = snapshot.data!.docs;
        if (items.isEmpty) {
          return const StoreMessageState(
            icon: Icons.favorite_border,
            title: 'Your wishlist is empty',
            message: 'Save pieces you love to come back to whenever you are ready.',
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = items[index];
                final item = doc.data();
                final price = (item['price'] as num?)?.toDouble() ?? 0;
                final name = item['name'] as String? ?? 'Product';
                final imageUrl = item['imageUrl'] as String? ?? '';

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: AppColors.warmBeige,
                              child: ProductImage(url: imageUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.midnight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove from wishlist',
                          onPressed: () => context
                              .read<ShopRepository>()
                              .removeFromWishlist(doc.id),
                          icon: const Icon(
                            Icons.favorite,
                            color: AppColors.gold,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ),
  );
}
