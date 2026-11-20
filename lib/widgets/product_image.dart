import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: AppColors.warmBeige,
        child: Center(
          child: Icon(
            Icons.child_friendly_outlined,
            color: AppColors.navy,
            size: 52,
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.warmBeige,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.navy,
          ),
        ),
      ),
    );
  }
}
