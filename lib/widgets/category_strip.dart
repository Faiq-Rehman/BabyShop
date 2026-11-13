import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../services/shop_repository.dart';

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<ShopRepository>().categories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Could not load categories: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
          );
        }
        final categories = snapshot.data!.docs;
        if (categories.isEmpty) {
          return const Text('No categories available yet.');
        }
        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final name =
                  categories[index].data()['name'] as String? ?? 'Category';
              final isSelected = selected == name;
              return ChoiceChip(
                label: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? AppColors.midnight : AppColors.midnight,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(name),
                backgroundColor: AppColors.warmBeige,
                selectedColor: AppColors.warmBeige,
                side: isSelected
                    ? const BorderSide(color: AppColors.gold, width: 2)
                    : const BorderSide(color: Colors.transparent, width: 2),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              );
            },
          ),
        );
      },
    );
  }
}
