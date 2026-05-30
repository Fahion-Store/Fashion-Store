import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _couponCode = '';
  double _couponDiscountPercentage = 0.0;

  CartProvider() {
    // Listen for auth changes to load the correct cart
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _syncOnLogin(user.uid);
      } else {
        _items.clear();
        _couponCode = '';
        _couponDiscountPercentage = 0.0;
        notifyListeners();
      }
    });
  }

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.values.fold(0, (total, item) => total + item.quantity);

  double get totalPrice =>
      _items.values.fold(0.0, (total, item) => total + item.totalPrice);

  String get couponCode => _couponCode;
  double get couponDiscountPercentage => _couponDiscountPercentage;
  double get discountAmount => totalPrice * _couponDiscountPercentage;
  double get shippingCost => (totalPrice - discountAmount) >= 2000.0 || totalPrice == 0.0 ? 0.0 : 250.0;
  double get subtotal => totalPrice;
  double get finalTotal => totalPrice - discountAmount + shippingCost;

  bool applyCoupon(String code) {
    if (code.trim().toUpperCase() == 'FIRST20') {
      _couponCode = 'FIRST20';
      _couponDiscountPercentage = 0.20;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _couponCode = '';
    _couponDiscountPercentage = 0.0;
    notifyListeners();
  }

  bool isInCart(String productId) => _items.containsKey(productId);

  void addItem(Product product, {String? size}) {
    final key = '${product.id}_${size ?? "default"}';
    if (_items.containsKey(key)) {
      _items[key] = _items[key]!.copyWith(
        quantity: _items[key]!.quantity + 1,
      );
    } else {
      _items[key] = CartItem(
        id: key,
        product: product,
        quantity: 1,
        selectedSize: size,
      );
    }
    notifyListeners();
    _saveCartToFirestore();
  }

  void removeItem(String key) {
    _items.remove(key);
    notifyListeners();
    _saveCartToFirestore();
  }

  void updateQuantity(String key, int quantity) {
    if (!_items.containsKey(key)) return;
    if (quantity <= 0) {
      removeItem(key);
      return;
    }
    _items[key] = _items[key]!.copyWith(quantity: quantity);
    notifyListeners();
    _saveCartToFirestore();
  }

  void clearCart() {
    _items.clear();
    _couponCode = '';
    _couponDiscountPercentage = 0.0;
    notifyListeners();
    _saveCartToFirestore();
  }

  // ── Firestore Sync ─────────────────────────────────────────────────────────

  Future<void> _syncOnLogin(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['cart'] != null) {
        final List<dynamic> cartList = doc.data()!['cart'];
        
        // Merge cloud items into local cart
        for (var itemMap in cartList) {
          final cloudItem = CartItem.fromMap(Map<String, dynamic>.from(itemMap));
          // If item already in local cart, maybe sum quantities? 
          // For simplicity, we'll let the cloud item take precedence if conflict,
          // or just add if new.
          if (!_items.containsKey(cloudItem.id)) {
            _items[cloudItem.id] = cloudItem;
          }
        }
        notifyListeners();
      }
      
      // After merging, push the combined cart back to Firestore
      await _saveCartToFirestore();
    } catch (e) {
      debugPrint('Error syncing cart on login: $e');
    }
  }

  Future<void> _saveCartToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Firestore Sync Skip: No user logged in');
      return;
    }

    try {
      final cartData = _items.values.map((item) => item.toMap()).toList();
      debugPrint('Syncing ${cartData.length} items to Firestore for user: ${user.uid}');
      
      final batch = _db.batch();

      // 1. Save to users/{uid}/cart (Nested)
      final userRef = _db.collection('users').doc(user.uid);
      batch.set(userRef, {
        'cart': cartData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Save to carts/{uid} (Top-level collection)
      final cartRef = _db.collection('carts').doc(user.uid);
      batch.set(cartRef, {
        'items': cartData,
        'userId': user.uid,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('Firestore Sync Success: Saved to "users" and "carts" collections');
    } catch (e) {
      debugPrint('Error saving cart to Firestore: $e');
    }
  }

}