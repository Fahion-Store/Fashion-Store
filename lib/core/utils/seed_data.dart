import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/product.dart';

class SeedData {
  static Future<void> uploadDummyProducts() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final productsCollection = db.collection('products');

    debugPrint('Starting data seeding...');

    try {
      final WriteBatch batch = db.batch();
      
      for (var product in Product.dummyProducts) {
        final docRef = productsCollection.doc(product.id);
        batch.set(docRef, product.toMap());
        debugPrint('Queued product for seeding: ${product.name}');
      }

      await batch.commit();
      debugPrint('Data seeding completed successfully!');
    } catch (e) {
      debugPrint('Error during data seeding: $e');
    }
  }
}
