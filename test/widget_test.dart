// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babyshop/models/product.dart';
import 'package:babyshop/models/delivery_details.dart';
import 'package:babyshop/core/widgets/success_popup.dart';
import 'package:babyshop/widgets/store_message_state.dart';

void main() {
  test('delivery details are saved as structured Pakistan address fields', () {
    const details = DeliveryDetails(
      fullName: '  Ayesha Khan ',
      phone: '03001234567',
      province: 'Punjab',
      city: 'Lahore',
      area: 'DHA Phase 6',
      address: 'House 12, Street 4',
      landmark: 'Near park',
      postalCode: '54000',
      deliveryInstructions: 'Call on arrival',
    );

    expect(
      details.formattedAddress,
      'House 12, Street 4, DHA Phase 6, Lahore, Punjab, 54000, Pakistan',
    );
    expect(details.toMap(), {
      'fullName': 'Ayesha Khan',
      'phone': '03001234567',
      'province': 'Punjab',
      'city': 'Lahore',
      'area': 'DHA Phase 6',
      'address': 'House 12, Street 4',
      'landmark': 'Near park',
      'postalCode': '54000',
      'deliveryInstructions': 'Call on arrival',
      'country': 'Pakistan',
    });
  });

  test('shared brand logo is bundled as a Flutter asset', () async {
    final logo = await rootBundle.load('assets/images/logo.jpg');
    expect(logo.lengthInBytes, greaterThan(0));
  });

  testWidgets('message state scrolls without overflowing a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 50,
            child: StoreMessageState(
              icon: Icons.search_off,
              title: 'No products found',
              message: 'Please check back later.',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -40));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('product data is parsed safely from Firestore fields', () {
    final product = Product.fromMap('onesie-1', {
      'name': 'Organic cotton onesie',
      'brand': 'Little Sprout',
      'categoryName': 'Clothing',
      'price': 18.5,
      'stock': 4,
      'isActive': true,
    });

    expect(product.id, 'onesie-1');
    expect(product.name, 'Organic cotton onesie');
    expect(product.category, 'Clothing');
    expect(product.price, 18.5);
    expect(product.stock, 4);
    expect(product.isActive, isTrue);
    expect(product.imageUrl, isEmpty);
  });

  test('missing or malformed optional product fields use safe defaults', () {
    final product = Product.fromMap('incomplete', {
      'price': 'not-a-number',
      'stock': -1,
    });

    expect(product.name, isEmpty);
    expect(product.price, 0);
    expect(product.stock, -1);
    expect(product.isActive, isFalse);
  });

  test('products can be deduplicated by id and name+brand', () {
    final list = [
      Product.fromMap('1', {
        'name': 'Baby Romper',
        'brand': 'Pekaboo',
        'price': 10,
        'stock': 5,
        'isActive': true,
      }),
      Product.fromMap('2', {
        'name': 'Baby Romper',
        'brand': 'Pekaboo',
        'price': 10,
        'stock': 5,
        'isActive': true,
      }),
      Product.fromMap('3', {
        'name': 'Teether Toy',
        'brand': 'Nuby',
        'price': 6,
        'stock': 2,
        'isActive': true,
      }),
    ];

    final seenIds = <String>{};
    final seenKeys = <String>{};
    final deduped = <Product>[];
    for (final p in list) {
      final key =
          '${p.name.trim().toLowerCase()}_${p.brand.trim().toLowerCase()}';
      if (seenIds.add(p.id) && seenKeys.add(key)) {
        deduped.add(p);
      }
    }

    expect(deduped.length, 2);
    expect(deduped.first.name, 'Baby Romper');
    expect(deduped.last.name, 'Teether Toy');
  });

  testWidgets(
    'cart success toast counts down and dismisses after three seconds',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCartSuccess(context),
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(find.text('Product added to cart successfully!'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, inInclusiveRange(0.35, 0.65));

      await tester.pump(const Duration(milliseconds: 1180));
      expect(find.text('Product added to cart successfully!'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 219));
      expect(find.text('Product added to cart successfully!'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Product added to cart successfully!'), findsNothing);
    },
  );
}
