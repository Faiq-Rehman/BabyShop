import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../services/shop_repository.dart';
import '../../widgets/store_message_state.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => Scaffold(
    backgroundColor: AppColors.ivory,
    appBar: AppBar(
      title: const Text(
        'Boutique Categories',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<ShopRepository>().categories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StoreMessageState(
            icon: Icons.error_outline,
            title: 'Categories unavailable',
            message: '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) return const LoadingWidget();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const StoreMessageState(
            icon: Icons.category_outlined,
            title: 'Categories are on their way',
            message: 'Our curated collections will be available shortly.',
          );
        }
        return Scrollbar(
          thumbVisibility: true,
          interactive: true,
          controller: _scrollController,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.15,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final item = docs[index].data();
                  final name = item['name'] as String? ?? 'Category';
                  final isSelected = widget.selected == name;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => widget.onSelected(name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.warmBeige : AppColors.ivory,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.warmBeige,
                          width: isSelected ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.midnight.withValues(
                              alpha: isSelected ? 0.08 : 0.04,
                            ),
                            blurRadius: isSelected ? 16 : 8,
                            offset: Offset(0, isSelected ? 6 : 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.ivory : AppColors.warmBeige,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: AppColors.gold, width: 1.5)
                                  : null,
                            ),
                            child: Icon(
                              _categoryIcon(name),
                              color: isSelected ? AppColors.midnight : AppColors.navy,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}

IconData _categoryIcon(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('cloth') || normalized.contains('wear')) {
    return Icons.checkroom_outlined;
  }
  if (normalized.contains('toy') || normalized.contains('play')) {
    return Icons.toys_outlined;
  }
  if (normalized.contains('feed') || normalized.contains('food')) {
    return Icons.restaurant_outlined;
  }
  if (normalized.contains('bath') || normalized.contains('care')) {
    return Icons.bathtub_outlined;
  }
  if (normalized.contains('sleep') || normalized.contains('bed')) {
    return Icons.bed_outlined;
  }
  return Icons.child_friendly_outlined;
}
