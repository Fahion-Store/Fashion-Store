import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../core/services/database_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ProductProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<String> _recentlyViewedIds = [];
  bool _isLoading = false;
  String? _error;

  ProductProvider() {
    _loadRecentlyViewed();
  }

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Product> get recentlyViewedProducts {
    final list = <Product>[];
    for (final id in _recentlyViewedIds) {
      final match = _products.any((p) => p.id == id);
      if (match) {
        list.add(_products.firstWhere((p) => p.id == id));
      }
    }
    return list;
  }

  // Load recently viewed IDs from SharedPreferences
  Future<void> _loadRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentlyViewedIds = prefs.getStringList('recentlyViewed') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recently viewed: $e');
    }
  }

  // Save recently viewed IDs to SharedPreferences
  Future<void> _saveRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recentlyViewed', _recentlyViewedIds);
    } catch (e) {
      debugPrint('Error saving recently viewed: $e');
    }
  }

  // Add product to recently viewed
  void addToRecentlyViewed(String productId) {
    _recentlyViewedIds.remove(productId); // Remove if exists to move to top
    _recentlyViewedIds.insert(0, productId);
    if (_recentlyViewedIds.length > 6) {
      _recentlyViewedIds = _recentlyViewedIds.sublist(0, 6);
    }
    notifyListeners();
    _saveRecentlyViewed();
  }

  // Fetch all products
  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (_products.isNotEmpty && !forceRefresh) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _dbService.getProducts();
      _featuredProducts = _products.where((p) => p.isFeatured).toList();
    } catch (e) {
      _error = 'Failed to load products';
      debugPrint('Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter products locally (or fetch from DB)
  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }
}
