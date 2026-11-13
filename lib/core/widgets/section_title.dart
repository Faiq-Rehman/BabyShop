import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, this.action, this.onTap, super.key});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Gold left-border accent
      Container(
        width: 3,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.midnight,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          child: Text(action!),
        ),
    ],
  );
}
