import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class WishlistProvider with ChangeNotifier {
  final List<Product> _wishlistItems = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  WishlistProvider() {
    if (_auth.currentUser != null) {
      _syncOnLogin(_auth.currentUser!.uid);
    }
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _syncOnLogin(user.uid);
      } else {
        _wishlistItems.clear();
        notifyListeners();
      }
    });
  }

  List<Product> get items => [..._wishlistItems];

  int get count => _wishlistItems.length;

  bool isWishlisted(String productId) {
    return _wishlistItems.any((p) => p.id == productId);
  }

  void toggleWishlist(Product product) {
    final index = _wishlistItems.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _wishlistItems.removeAt(index);
    } else {
      _wishlistItems.add(product);
    }
    notifyListeners();
    _saveWishlistToFirestore();
  }

  void clearWishlist() {
    _wishlistItems.clear();
    notifyListeners();
    _saveWishlistToFirestore();
  }

  // ── Firestore Sync ─────────────────────────────────────────────────────────

  Future<void> _saveWishlistToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final wishlistData = _wishlistItems.map((item) => item.toMap()).toList();
      await _db.collection('users').doc(user.uid).set({
        'wishlist': wishlistData,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving wishlist to Firestore: $e');
    }
  }

  Future<void> _syncOnLogin(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['wishlist'] != null) {
        final List<dynamic> wishlistList = doc.data()!['wishlist'];
        
        // Merge cloud items into local wishlist
        for (var itemMap in wishlistList) {
          final cloudItem = Product.fromMap(Map<String, dynamic>.from(itemMap), itemMap['id']);
          if (!_wishlistItems.any((p) => p.id == cloudItem.id)) {
            _wishlistItems.add(cloudItem);
          }
        }
        notifyListeners();
      }
      // Push merged wishlist back to cloud
      await _saveWishlistToFirestore();
    } catch (e) {
      debugPrint('Error syncing wishlist on login: $e');
    }
  }
}
