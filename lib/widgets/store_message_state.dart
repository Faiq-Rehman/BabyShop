import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class StoreMessageState extends StatelessWidget {
  const StoreMessageState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content = Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: AppColors.midnight),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
      if (!constraints.hasBoundedHeight) return Center(child: content);
      return SingleChildScrollView(
        primary: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: content),
        ),
      );
    },
  );
}
