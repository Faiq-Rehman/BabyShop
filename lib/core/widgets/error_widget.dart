import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

void showErrorMessage(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Could not complete the action: $error',
        style: const TextStyle(color: AppColors.ivory),
      ),
      backgroundColor: AppColors.midnight,
    ),
  );
}
