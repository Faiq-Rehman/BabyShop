import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/delivery_details.dart';
import '../models/product.dart';

class ShopRepository {
  ShopRepository({required this._firestore, required this._auth});

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before using the store.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _userCart =>
      _firestore.collection('users').doc(_uid).collection('cart');

  CollectionReference<Map<String, dynamic>> get _wishlist =>
      _firestore.collection('users').doc(_uid).collection('wishlist');

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication did not return a user.');
    }
    await user.updateDisplayName(name);
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'role': 'customer',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Stream<QuerySnapshot<Map<String, dynamic>>> products() => _firestore
      .collection('products')
      .where('isActive', isEqualTo: true)
      .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> product(String productId) =>
      _firestore.collection('products').doc(productId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> categories() => _firestore
      .collection('categories')
      .where('isActive', isEqualTo: true)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> cartItems() =>
      _userCart.snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> wishlistItems() =>
      _wishlist.snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> wishlistItem(
    String productId,
  ) => _wishlist.doc(productId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> orders() => _firestore
      .collection('orders')
      .where('userId', isEqualTo: _uid)
      .snapshots();

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (!product.isActive) throw StateError('This product is not available.');
    if (quantity < 1) throw ArgumentError.value(quantity, 'quantity');
    final productRef = _firestore.collection('products').doc(product.id);
    final itemRef = _userCart.doc(product.id);
    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      final cartSnapshot = await transaction.get(itemRef);
      if (!productSnapshot.exists) {
        throw StateError('This product is no longer available.');
      }
      final productData = productSnapshot.data()!;
      final stock = (productData['stock'] as num?)?.toInt() ?? 0;
      final currentQuantity =
          (cartSnapshot.data()?['quantity'] as num?)?.toInt() ?? 0;
      if (currentQuantity + quantity > stock) {
        throw StateError('There is not enough stock for this quantity.');
      }
      transaction.set(itemRef, {
        'productId': product.id,
        'name': productData['name'] as String? ?? product.name,
        'imageUrl': productData['imageUrl'] as String? ?? product.imageUrl,
        'price': (productData['price'] as num?)?.toDouble() ?? product.price,
        'quantity': currentQuantity + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> setCartQuantity(String productId, int quantity) async {
    final itemRef = _userCart.doc(productId);
    if (quantity <= 0) {
      await itemRef.delete();
      return;
    }
    final productRef = _firestore.collection('products').doc(productId);
    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) {
        throw StateError('This product is no longer available.');
      }
      final productData = productSnapshot.data()!;
      final stock = (productData['stock'] as num?)?.toInt() ?? 0;
      if (quantity > stock) {
        throw StateError('Only $stock items are currently available.');
      }
      transaction.update(itemRef, {
        'quantity': quantity,
        'price': (productData['price'] as num?)?.toDouble() ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> toggleWishlist(Product product) async {
    final item = _wishlist.doc(product.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(item);
      if (snapshot.exists) {
        transaction.delete(item);
      } else {
        transaction.set(item, {
          'productId': product.id,
          'name': product.name,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> removeFromWishlist(String productId) =>
      _wishlist.doc(productId).delete();

  Future<({String orderId, double total})> placeOrder({
    required DeliveryDetails deliveryDetails,
  }) async {
    final cartSnapshot = await _userCart.get();
    if (cartSnapshot.docs.isEmpty) {
      throw StateError('Your cart is empty.');
    }
    if (cartSnapshot.docs.length > 100) {
      throw StateError('Your cart has too many products for one order.');
    }

    final orderItems = <Map<String, dynamic>>[];
    var total = 0.0;
    var itemCount = 0;
    for (final cartItem in cartSnapshot.docs) {
      final cartData = cartItem.data();
      final quantity = (cartData['quantity'] as num?)?.toInt() ?? 0;
      final productSnapshot = await _firestore
          .collection('products')
          .doc(cartItem.id)
          .get();
      final product = productSnapshot.data();
      if (product == null || product['isActive'] != true) {
        throw StateError(
          '${cartData['name'] ?? 'A product'} is no longer available.',
        );
      }

      final stock = (product['stock'] as num?)?.toInt() ?? 0;
      if (quantity < 1 || quantity > stock) {
        throw StateError(
          '${product['name'] ?? 'A product'} does not have enough stock.',
        );
      }
      final unitPrice = (product['price'] as num?)?.toDouble() ?? 0;
      final lineTotal = (unitPrice * quantity * 100).round() / 100;
      total = ((total + lineTotal) * 100).round() / 100;
      itemCount += quantity;
      orderItems.add({
        'productId': productSnapshot.id,
        'name': product['name'] as String? ?? '',
        'imageUrl': product['imageUrl'] as String? ?? '',
        'unitPrice': unitPrice,
        'quantity': quantity,
        'lineTotal': lineTotal,
      });
    }

    final orderRef = _firestore.collection('orders').doc();
    final batch = _firestore.batch();
    batch.set(orderRef, {
      'userId': _uid,
      'items': orderItems,
      'itemCount': itemCount,
      'subtotal': total,
      'shipping': 0,
      'total': total,
      'address': deliveryDetails.formattedAddress,
      'deliveryDetails': deliveryDetails.toMap(),
      'paymentMethod': 'cash_on_delivery',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final cartItem in cartSnapshot.docs) {
      batch.delete(cartItem.reference);
    }
    await batch.commit();
    return (orderId: orderRef.id, total: total);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfile() =>
      _firestore.collection('users').doc(_uid).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() =>
      _firestore.collection('users').doc(_uid).get();

  Future<void> updateProfile({
    required String name,
    required String phone,
    required DeliveryDetails deliveryDetails,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before updating your profile.');
    }
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    final deliveryMap = deliveryDetails.toMap();
    deliveryMap['fullName'] = trimmedName;
    deliveryMap['phone'] = trimmedPhone;

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': trimmedName,
        'phone': trimmedPhone,
        'email': user.email ?? '',
        'role': 'customer',
        'isActive': true,
        'deliveryDetails': deliveryMap,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.set({
        'name': trimmedName,
        'phone': trimmedPhone,
        'deliveryDetails': deliveryMap,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    try {
      await user.updateDisplayName(trimmedName);
    } catch (_) {
      // Ignored if auth display name update fails
    }
  }

  Future<void> submitSupport(String message) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before contacting support.');
    final cleanedMessage = message.trim();
    if (cleanedMessage.isEmpty || cleanedMessage.length > 2000) {
      throw ArgumentError('Message must be between 1 and 2000 characters.');
    }
    await _firestore.collection('supportTickets').add({
      'userId': user.uid,
      'email': user.email,
      'message': cleanedMessage,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
