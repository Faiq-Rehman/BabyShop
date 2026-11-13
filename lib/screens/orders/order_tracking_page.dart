import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/store_message_state.dart';

class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({
    required this.orderId,
    required this.order,
    super.key,
  });

  final String orderId;
  final Map<String, dynamic> order;

  static const _steps = <String>[
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'out_for_delivery',
    'delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] as String? ?? 'pending').toLowerCase();
    final cancelled = status == 'cancelled';
    final currentIndex = _steps.indexOf(status);
    final history = (order['statusHistory'] as List<dynamic>? ?? const []);
    final orderItems = (order['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .toList();
    final recorded = <String>{'pending'};
    for (final entry in history) {
      if (entry is Map && entry['status'] is String) {
        recorded.add(entry['status'] as String);
      }
    }
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'Track Your Order',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.warmBeige, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnight.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ORDER REFERENCE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBeige,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.midnight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${order['itemCount'] ?? 0} item${(order['itemCount'] ?? 0) == 1 ? '' : 's'} · Total: \$${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (orderItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.warmBeige, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Items Ordered',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...orderItems.map((item) {
                        final name = item['name'] as String? ?? 'Product';
                        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                        final unitPrice =
                            (item['unitPrice'] as num?)?.toDouble() ?? 0;
                        final lineTotal =
                            (item['lineTotal'] as num?)?.toDouble() ??
                            unitPrice * quantity;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$name × $quantity',
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${lineTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.midnight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                cancelled ? 'Order Cancelled' : 'Delivery Progress',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 16),
              if (cancelled)
                const StoreMessageState(
                  icon: Icons.info_outline,
                  title: 'This order was cancelled',
                  message:
                      'If you need help with this order, please contact our support team.',
                )
              else
                ...List.generate(_steps.length, (index) {
                  final step = _steps[index];
                  final complete =
                      recorded.contains(step) ||
                      (currentIndex >= 0 && index <= currentIndex);
                  final active = status == step;
                  final title = step
                      .split('_')
                      .map((part) => part[0].toUpperCase() + part.substring(1))
                      .join(' ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: complete
                                      ? AppColors.gold
                                      : active
                                      ? AppColors.warmBeige
                                      : AppColors.warmBeige,
                                  shape: BoxShape.circle,
                                  border: active
                                      ? Border.all(color: AppColors.gold, width: 2)
                                      : null,
                                ),
                                child: Icon(
                                  complete
                                      ? Icons.check
                                      : active
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  size: active ? 10 : 15,
                                  color: complete
                                      ? AppColors.ivory
                                      : active
                                      ? AppColors.gold
                                      : AppColors.navy,
                                ),
                              ),
                              if (index != _steps.length - 1)
                                Container(
                                  width: 2.5,
                                  height: 44,
                                  color: complete
                                      ? AppColors.gold
                                      : AppColors.warmBeige,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3, bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: active || complete
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14.5,
                                    color: active
                                        ? AppColors.midnight
                                        : complete
                                        ? AppColors.midnight
                                        : AppColors.navy,
                                  ),
                                ),
                                if (active)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Your package is currently in this phase.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
              if ((order['address'] as String?)?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.warmBeige, width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warmBeige,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['deliveryDetails'] is Map &&
                                      (order['deliveryDetails'] as Map)['fullName']
                                          is String
                                  ? (order['deliveryDetails'] as Map)['fullName'] as String
                                  : 'Delivery Destination',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.midnight,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (order['deliveryDetails'] is Map &&
                                    (order['deliveryDetails'] as Map)['phone'] is String)
                                  (order['deliveryDetails'] as Map)['phone'] as String,
                                order['address'] as String,
                              ].join('\n'),
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
