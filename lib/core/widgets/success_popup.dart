import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

OverlayEntry? _cartSuccessEntry;

void showCartSuccess(BuildContext context) {
  final overlay = Overlay.of(context);
  _cartSuccessEntry?.remove();
  _cartSuccessEntry?.dispose();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CartSuccessToast(
      onDismiss: () {
        if (!identical(_cartSuccessEntry, entry)) return;
        _cartSuccessEntry = null;
        entry.remove();
        entry.dispose();
      },
    ),
  );
  _cartSuccessEntry = entry;
  overlay.insert(entry);
}

class _CartSuccessToast extends StatefulWidget {
  const _CartSuccessToast({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_CartSuccessToast> createState() => _CartSuccessToastState();
}

class _CartSuccessToastState extends State<_CartSuccessToast>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _progressController;
  late final Timer _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    _dismissTimer = Timer(const Duration(milliseconds: 2780), () async {
      await _controller.reverse();
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer.cancel();
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: FadeTransition(
                opacity: _controller,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.15),
                    end: Offset.zero,
                  ).animate(_controller),
                  child: Material(
                    color: AppColors.midnight,
                    elevation: 8,
                    shadowColor: AppColors.midnight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.gold),
                                SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Product added to cart successfully!',
                                    style: TextStyle(
                                      color: AppColors.ivory,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) => LinearProgressIndicator(
                              value: 1 - _progressController.value,
                              minHeight: 2,
                              backgroundColor: AppColors.navy,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
