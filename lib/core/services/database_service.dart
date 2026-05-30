import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';

import '../../models/order_model.dart';
import '../../models/review_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Orders ───────────────────────────────────────────────────────────────

  Future<String?> placeOrder(OrderModel order) async {
    try {
      final docRef = await _db.collection('orders').add(order.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return null;
    }
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final snapshot = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
          
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
          
      // Sort locally to avoid needing a Firestore composite index
      orders.sort((a, b) => b.date.compareTo(a.date));
      
      return orders;
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
      return [];
    }
  }

  // ── Products ───────────────────────────────────────────────────────────────

  // Get all products
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _db.collection('products').get();
      return snapshot.docs.map((doc) => _productFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('isFeatured', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => _productFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
      return [];
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs.map((doc) => _productFromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching products by category: $e');
      return [];
    }
  }

  // Helper: Map Firestore document to Product model
  Product _productFromFirestore(DocumentSnapshot doc) {
    return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ── User Data (Cart/Wishlist/Addresses) ────────────────────────────────────

  // Sync cart to Firestore
  Future<void> syncCart(String userId, List<Map<String, dynamic>> cartItems) async {
    await _db.collection('users').doc(userId).set({
      'cart': cartItems,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Sync wishlist to Firestore
  Future<void> syncWishlist(String userId, List<String> productIds) async {
    await _db.collection('users').doc(userId).set({
      'wishlist': productIds,
    }, SetOptions(merge: true));
  }

  // ── Reviews ────────────────────────────────────────────────────────────────
  
  Future<int> getUserReviewsCount(String userId) async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching user reviews count: $e');
      return 0;
    }
  }

  Future<void> addReview(Review review) async {
    try {
      await _db.collection('reviews').add(review.toMap());
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
  }

  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching product reviews: $e');
      return [];
    }
  }
}
