import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/shop_repository.dart';
import '../screens/home/shop_page.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class BabyShopHubApp extends StatelessWidget {
  const BabyShopHubApp({super.key});

  @override
  Widget build(BuildContext context) => Provider<ShopRepository>(
    create: (_) => ShopRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    ),
    child: MaterialApp(
      title: 'BabyShop',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true),
      theme: AppTheme.light,
      home: const ShopPage(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    ),
  );
}
