import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    this.eyebrow,
    this.action,
    this.onTap,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 3.5,
        height: eyebrow != null && eyebrow!.isNotEmpty ? 30 : 20,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (eyebrow != null && eyebrow!.isNotEmpty) ...[
              Text(
                eyebrow!.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
              ),
            ),
          ],
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          child: Text(action!),
        ),
    ],
  );
}
