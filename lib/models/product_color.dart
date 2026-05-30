import 'package:flutter/material.dart';

class ProductColor {
  final String name;
  final Color color;
  final String imageUrl;

  const ProductColor({
    required this.name,
    required this.color,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}', // Store as #RRGGBB
      'imageUrl': imageUrl,
    };
  }
}