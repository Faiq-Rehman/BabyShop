import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/widgets/section_title.dart';
import '../models/product.dart';
import '../services/shop_repository.dart';
import 'product_card.dart';
import 'store_message_state.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({required this.category, required this.search, super.key});

  final String category;
  final String search;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<ShopRepository>().products(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: StoreMessageState(
              icon: Icons.cloud_off_outlined,
              title: 'Products unavailable',
              message: '${snapshot.error}',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }

        final normalizedSearch = search.toLowerCase();

        // 1. DEDUPLICATE PRODUCTS
        // Remove any products that have duplicate IDs or duplicate (name + brand) keys.
        final seenIds = <String>{};
        final seenKeys = <String>{};
        final dedupedProducts = <Product>[];

        for (final doc in snapshot.data!.docs) {
          final product = Product.fromFirestore(doc);
          if (!product.isActive || product.stock <= 0) continue;
          if (category.isNotEmpty &&
              product.category.toLowerCase() != category.toLowerCase()) {
            continue;
          }
          if (normalizedSearch.isNotEmpty) {
            final matches =
                product.name.toLowerCase().contains(normalizedSearch) ||
                product.brand.toLowerCase().contains(normalizedSearch) ||
                product.category.toLowerCase().contains(normalizedSearch);
            if (!matches) continue;
          }

          final key =
              '${product.name.trim().toLowerCase()}_${product.brand.trim().toLowerCase()}';
          if (seenIds.add(product.id) && seenKeys.add(key)) {
            dedupedProducts.add(product);
          }
        }

        if (dedupedProducts.isEmpty) {
          return SliverToBoxAdapter(
            child: StoreMessageState(
              icon: Icons.search_off,
              title: 'No products found',
              message: search.isEmpty
                  ? 'Products will appear here when the store is ready.'
                  : 'Try a different search or category.',
            ),
          );
        }

        // 2. PARTITION PRODUCTS WITHOUT DUPLICATION
        // If searching or filtering by category, or if products count <= 4,
        // show all products in the main grid so nothing is repeated.
        final shouldShowNewArrivalsSlider =
            search.isEmpty && category.isEmpty && dedupedProducts.length > 4;

        final List<Product> newArrivals;
        final List<Product> mainGridProducts;

        if (shouldShowNewArrivalsSlider) {
          final docMap = {for (final d in snapshot.data!.docs) d.id: d};
          final candidates = List<Product>.from(dedupedProducts);
          candidates.sort((first, second) {
            final firstDate = docMap[first.id]?.data()['createdAt'];
            final secondDate = docMap[second.id]?.data()['createdAt'];
            if (firstDate is Timestamp && secondDate is Timestamp) {
              return secondDate.compareTo(firstDate);
            }
            return 0;
          });

          // Up to 4 newest items in the slider
          newArrivals = candidates.take(4).toList();
          final arrivalIds = newArrivals.map((p) => p.id).toSet();

          // Main grid gets STRICTLY the remaining products to avoid any duplicate cards!
          mainGridProducts = dedupedProducts
              .where((p) => !arrivalIds.contains(p.id))
              .toList();
        } else {
          newArrivals = const <Product>[];
          mainGridProducts = dedupedProducts;
        }

        if (FirebaseAuth.instance.currentUser == null) {
          return _productCards(
            context,
            mainGridProducts,
            const {},
            newArrivals,
            search.isNotEmpty || category.isNotEmpty,
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: context.read<ShopRepository>().wishlistItems(),
          builder: (context, wishlistSnapshot) {
            final wishlistIds =
                wishlistSnapshot.data?.docs.map((item) => item.id).toSet() ??
                const <String>{};
            return _productCards(
              context,
              mainGridProducts,
              wishlistIds,
              newArrivals,
              search.isNotEmpty || category.isNotEmpty,
            );
          },
        );
      },
    );
  }

  Widget _productCards(
    BuildContext context,
    List<Product> products,
    Set<String> wishlistIds,
    List<Product> newArrivals,
    bool isFiltering,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        if (newArrivals.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'New arrivals',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.midnight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 335,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: newArrivals.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) => SizedBox(
                      width: 215,
                      child: ProductCard(
                        key: ValueKey('arrival_${newArrivals[index].id}'),
                        product: newArrivals[index],
                        isWishlisted: wishlistIds.contains(
                          newArrivals[index].id,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        if (products.isNotEmpty && newArrivals.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SectionTitle(title: 'More essentials for baby'),
            ),
          ),
        if (isFiltering && products.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Showing ${products.length} distinct item${products.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent > 1100
                  ? 4
                  : constraints.crossAxisExtent > 700
                  ? 3
                  : 2;
              final tileHeight = constraints.crossAxisExtent < 380
                  ? 330.0
                  : constraints.crossAxisExtent < 700
                  ? 335.0
                  : 340.0;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: tileHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    key: ValueKey('grid_${products[index].id}'),
                    product: products[index],
                    isWishlisted: wishlistIds.contains(products[index].id),
                  ),
                  childCount: products.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
