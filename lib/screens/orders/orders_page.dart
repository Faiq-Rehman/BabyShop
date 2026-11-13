import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../services/shop_repository.dart';
import '../../widgets/store_message_state.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: context.read<ShopRepository>().orders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return StoreMessageState(
              icon: Icons.error_outline,
              title: 'Orders unavailable',
              message: '${snapshot.error}',
            );
          }
          if (!snapshot.hasData) return const LoadingWidget();
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const StoreMessageState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Your luxury purchases and order history will appear here.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView.separated(
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final orderDocument = orders[index];
                  final data = orderDocument.data();
                  final amount = (data['total'] as num?)?.toDouble() ?? 0;
                  final createdAt = data['createdAt'];
                  final orderDate = createdAt is Timestamp
                      ? createdAt.toDate().toLocal()
                      : null;
                  final status = (data['status'] as String? ?? 'Pending');
                  final itemCount = (data['itemCount'] as num?)?.toInt() ?? 0;

                  return Container(
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
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => AppRoutes.push<void>(
                        context,
                        AppRoutes.orderTracking,
                        arguments: OrderTrackingRouteArguments(
                          orderId: orderDocument.id,
                          order: data,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '#',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      orderDocument.id.substring(
                                        0,
                                        orderDocument.id.length > 8 ? 8 : orderDocument.id.length,
                                      ).toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Georgia',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.midnight,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.navy,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  orderDate == null
                                      ? 'Date unavailable'
                                      : MaterialLocalizations.of(context).formatMediumDate(orderDate),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 14,
                                  color: AppColors.navy,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$itemCount item${itemCount == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: AppColors.warmBeige),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Order Total',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.navy,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '\$${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.midnight,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Track Order',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warmBeige,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
