import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../core/constants/app_colors.dart';

class SignInPrompt extends StatelessWidget {
  const SignInPrompt({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      primary: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
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
                  child: const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: AppColors.midnight,
                  ),
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
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () => openAuth(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.ivory,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign in or create account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
