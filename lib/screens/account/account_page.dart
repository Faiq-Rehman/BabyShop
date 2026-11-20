import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../services/shop_repository.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({required this.user, super.key});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final accountUser = user;
    if (accountUser == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            primary: false,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.warmBeige,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.midnight,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to BabyShop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: AppColors.midnight,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A World of Little Wonders.\nSign in to view your orders, save items to your wishlist, and enjoy personalized boutique service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => openAuth(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.ivory,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In or Create Account',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Enjoy shopping our luxury collection as a guest',
                  style: TextStyle(color: AppColors.navy, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = accountUser.displayName?.trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: context.read<ShopRepository>().userProfile(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final delivery = data?['deliveryDetails'] as Map<String, dynamic>?;
            final savedName = (data?['name'] as String?)?.trim();
            final savedPhone = (data?['phone'] as String?)?.trim() ??
                (delivery?['phone'] as String?)?.trim();
            final savedCity = (delivery?['city'] as String?)?.trim();

            final nameToDisplay = (savedName != null && savedName.isNotEmpty)
                ? savedName
                : (displayName?.isNotEmpty == true
                    ? displayName!
                    : 'BabyShop Customer');

            return ListView(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // Luxury User Profile Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warmBeige, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.midnight.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.midnight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.gold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameToDisplay,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              accountUser.email ?? '',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                              ),
                            ),
                            if ((savedPhone != null && savedPhone.isNotEmpty) ||
                                (savedCity != null && savedCity.isNotEmpty)) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (savedPhone != null && savedPhone.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: AppColors.gold,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          savedPhone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (savedCity != null && savedCity.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
                                          color: AppColors.gold,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          savedCity,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warmBeige,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'VALUED MEMBER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnight,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Navigation Links
                _accountMenuCard(
                  context,
                  icon: Icons.person_outline,
                  title: 'My Profile & Address',
                  subtitle: 'Manage your contact details and default delivery address',
                  onTap: () => AppRoutes.push<void>(context, AppRoutes.profile),
                ),
                const SizedBox(height: 10),
                _accountMenuCard(
                  context,
                  icon: Icons.local_shipping_outlined,
                  title: 'My Orders & Order History',
                  subtitle: 'Track your deliveries and review past orders',
                  onTap: () => AppRoutes.push<void>(context, AppRoutes.orders),
                ),
                const SizedBox(height: 10),
                _accountMenuCard(
                  context,
                  icon: Icons.favorite_border,
                  title: 'Wishlist & Saved Items',
                  subtitle: 'Find all the pieces you loved for your baby',
                  onTap: () => openWishlist(context),
                ),
                const SizedBox(height: 10),
                _accountMenuCard(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Concierge & Support',
                  subtitle: 'Our dedicated customer care team is here to assist',
                  onTap: () => AppRoutes.push<void>(context, AppRoutes.support),
                ),
                const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<ShopRepository>().signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have signed out of BabyShop.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.navy),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.warmBeige, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _accountMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warmBeige, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.navy, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: AppColors.midnight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.navy),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.chevron_right, size: 16, color: AppColors.gold),
        ),
        onTap: onTap,
      ),
    );
  }
}
