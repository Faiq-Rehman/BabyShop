import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.ivory,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.gold,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Loading…',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );
}
