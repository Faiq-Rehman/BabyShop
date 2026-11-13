import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../services/shop_repository.dart';
import '../account/account_page.dart';
import '../cart/cart_page.dart';
import '../categories/category_page.dart';
import 'home_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _tab = 0;
  String _category = '';
  final _collectionKey = GlobalKey();
  User? _user;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _user = user;
        if (user != null && _tab == 3) {
          // Keep current tab if already viewing account
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hasTopNavigation = screenWidth >= 900;
    final isWideNavigation = screenWidth >= 1180;
    final pageContent = IndexedStack(
      index: _tab,
      children: [
        HomePage(
          user: _user,
          category: _category,
          collectionKey: _collectionKey,
          onCategorySelected: (category) =>
              setState(() => _category = category),
          onSeeAllCategories: () => setState(() => _tab = 1),
        ),
        CategoryPage(
          selected: _category,
          onSelected: (category) {
            setState(() {
              _category = category;
              _tab = 0;
            });
          },
        ),
        CartPage(key: ValueKey(_user?.uid ?? 'guest')),
        AccountPage(user: _user),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.midnight,
        foregroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  semanticLabel: 'BabyShop logo',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'BabyShop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: AppColors.ivory,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (screenWidth >= 460)
                    const Text(
                      'A World of Little Wonders.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (hasTopNavigation) ...[
            _TopNavigationButton(
              label: 'Home',
              icon: Icons.home_outlined,
              selected: _tab == 0,
              onPressed: () => setState(() => _tab = 0),
            ),
            _TopNavigationButton(
              label: 'Categories',
              icon: Icons.grid_view_rounded,
              selected: _tab == 1,
              onPressed: () => setState(() => _tab = 1),
            ),
            _TopNavigationButton(
              label: 'Shop Collection',
              icon: Icons.auto_awesome_outlined,
              selected: false,
              onPressed: _showCollection,
            ),
            if (isWideNavigation)
              _TopNavigationButton(
                label: 'Wishlist',
                icon: Icons.favorite_border,
                selected: false,
                onPressed: () => openWishlist(context),
              )
            else
              IconButton(
                tooltip: 'Wishlist',
                onPressed: () => openWishlist(context),
                icon: const Icon(Icons.favorite_border),
                color: AppColors.ivory,
              ),
            _TopNavigationButton(
              label: 'Cart',
              icon: Icons.shopping_bag_outlined,
              selected: _tab == 2,
              onPressed: () => setState(() => _tab = 2),
            ),
            if (isWideNavigation)
              _TopNavigationButton(
                label: 'Contact',
                icon: Icons.support_agent_outlined,
                selected: false,
                onPressed: () =>
                    AppRoutes.push<void>(context, AppRoutes.support),
              )
            else
              IconButton(
                tooltip: 'Contact',
                onPressed: () =>
                    AppRoutes.push<void>(context, AppRoutes.support),
                icon: const Icon(Icons.support_agent_outlined),
                color: AppColors.ivory,
              ),
            _AccountDropdown(
              user: _user,
              isSelected: _tab == 3,
              onSelectProfile: () => setState(() => _tab = 3),
              compact: !isWideNavigation,
            ),
          ] else ...[
            IconButton(
              tooltip: 'Wishlist',
              onPressed: () => openWishlist(context),
              icon: const Icon(Icons.favorite_border),
              color: AppColors.ivory,
            ),
            _AccountDropdown(
              user: _user,
              isSelected: _tab == 3,
              onSelectProfile: () => setState(() => _tab = 3),
              compact: true,
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              iconColor: AppColors.ivory,
              color: AppColors.ivory,
              onSelected: (value) async {
                switch (value) {
                  case 'shop':
                    _showCollection();
                    break;
                  case 'contact':
                    await AppRoutes.push<void>(context, AppRoutes.support);
                    break;
                  case 'orders':
                    if (_user == null) {
                      await openAuth(context);
                    } else {
                      await AppRoutes.push<void>(context, AppRoutes.orders);
                    }
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'shop', child: Text('Shop Collection')),
                PopupMenuItem(value: 'contact', child: Text('Contact')),
                PopupMenuItem(value: 'orders', child: Text('Orders')),
              ],
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: pageContent,
        ),
      ),
      bottomNavigationBar: hasTopNavigation
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Categories',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  label: 'Cart',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Account',
                ),
              ],
            ),
    );
  }

  void _showCollection() {
    setState(() => _tab = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _collectionKey.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.08,
        );
      }
    });
  }
}

class _TopNavigationButton extends StatelessWidget {
  const _TopNavigationButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? AppColors.gold : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: selected ? AppColors.gold : AppColors.ivory,
          backgroundColor: Colors.transparent,
          overlayColor: AppColors.gold.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          textStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
  );
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.user,
    required this.isSelected,
    required this.onSelectProfile,
    this.compact = false,
  });

  final User? user;
  final bool isSelected;
  final VoidCallback onSelectProfile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account menu',
      offset: const Offset(0, 46),
      elevation: 6,
      color: AppColors.ivory,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            onSelectProfile();
            break;
          case 'orders':
            if (user == null) {
              await openAuth(context);
            } else {
              AppRoutes.push<void>(context, AppRoutes.orders);
            }
            break;
          case 'wishlist':
            await openWishlist(context);
            break;
          case 'support':
            AppRoutes.push<void>(context, AppRoutes.support);
            break;
          case 'signin':
            await openAuth(context);
            break;
          case 'signout':
            await context.read<ShopRepository>().signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully.')),
              );
            }
            break;
        }
      },
      itemBuilder: (context) {
        if (user != null) {
          final displayName = user!.displayName?.trim();
          final email = user!.email?.trim();
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName?.isNotEmpty == true
                          ? displayName!
                          : 'BabyShop Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.navy,
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: AppColors.gold),
                  SizedBox(width: 12),
                  Text('My Profile & Account'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'orders',
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: AppColors.gold,
                  ),
                  SizedBox(width: 12),
                  Text('My Orders'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'wishlist',
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 20, color: AppColors.gold),
                  SizedBox(width: 12),
                  Text('Wishlist'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'support',
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    size: 20,
                    color: AppColors.gold,
                  ),
                  SizedBox(width: 12),
                  Text('Help & Support'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: AppColors.navy),
                  SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ];
        } else {
          return <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'signin',
              child: Row(
                children: [
                  Icon(Icons.login, size: 20, color: AppColors.gold),
                  SizedBox(width: 12),
                  Text(
                    'Sign In / Register',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.midnight,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: AppColors.gold),
                  SizedBox(width: 12),
                  Text('Guest Overview'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'orders',
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: AppColors.gold,
                  ),
                  SizedBox(width: 12),
                  Text('Track Orders'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'wishlist',
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 20, color: AppColors.gold),
                  SizedBox(width: 12),
                  Text('Wishlist'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'support',
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    size: 20,
                    color: AppColors.gold,
                  ),
                  SizedBox(width: 12),
                  Text('Contact Support'),
                ],
              ),
            ),
          ];
        }
      },
      child: compact
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user != null ? Icons.person : Icons.person_outline,
                    size: 20,
                    color: isSelected ? AppColors.midnight : AppColors.ivory,
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: AppColors.gold,
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected
                        ? AppColors.gold
                        : AppColors.navy,
                    child: Icon(
                      user != null ? Icons.person : Icons.person_outline,
                      size: 14,
                      color: isSelected ? AppColors.midnight : AppColors.ivory,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    user != null
                        ? (user!.displayName?.split(' ').first ?? 'Account')
                        : 'Account',
                    style: TextStyle(
                      color: isSelected ? AppColors.midnight : AppColors.ivory,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isSelected ? AppColors.midnight : AppColors.gold,
                  ),
                ],
              ),
            ),
    );
  }
}
