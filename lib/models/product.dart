import 'package:flutter/material.dart';
import 'product_color.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String description;
  final List<String> sizes;
  final List<ProductColor> colorOptions;
  final bool isFeatured;
  
  final double originalPrice;
  final double rating;
  final int reviewCount;
  final List<String> galleryImages;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.originalPrice = 0.0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.galleryImages = const [],
    this.description = '',
    this.sizes = const ['XS', 'S', 'M', 'L', 'XL'],
    this.colorOptions = const [],
    this.isFeatured = false,
  });

  // Dynamic getters for e-commerce features
  double get displayOriginalPrice => originalPrice > 0.0 ? originalPrice : (id.hashCode % 3 == 0 ? (price * 1.3 / 10).round() * 10.0 : price);
  double get displayRating => rating > 0.0 ? rating : double.parse((4.0 + (id.hashCode % 10) * 0.1).toStringAsFixed(1));
  int get displayReviewCount => reviewCount > 0 ? reviewCount : (id.hashCode % 120 + 8);
  List<String> get displayGalleryImages => galleryImages.isNotEmpty 
      ? galleryImages 
      : [imageUrl, ...colorOptions.map((c) => c.imageUrl).where((url) => url != imageUrl)];
  
  int get discountPercentage {
    final orig = displayOriginalPrice;
    if (orig <= price) return 0;
    return (((orig - price) / orig) * 100).round();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'sizes': sizes,
      'colorOptions': colorOptions.map((c) => c.toMap()).toList(),
      'isFeatured': isFeatured,
      'originalPrice': originalPrice,
      'rating': rating,
      'reviewCount': reviewCount,
      'galleryImages': galleryImages,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    final List<dynamic> colorsData = map['colorOptions'] ?? [];
    final List<ProductColor> colorOptions = colorsData.map((c) {
      final String colorStr = c['color'].toString().replaceFirst('#', 'FF');
      return ProductColor(
        name: c['name'],
        color: Color(int.parse(colorStr, radix: 16)),
        imageUrl: c['imageUrl'],
      );
    }).toList();

    return Product(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      sizes: List<String>.from(map['sizes'] ?? []),
      colorOptions: colorOptions,
      isFeatured: map['isFeatured'] ?? false,
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      galleryImages: List<String>.from(map['galleryImages'] ?? []),
    );
  }

  static List<Product> dummyProducts = [

    // ── Men ───────────────────────────────────────────────────────────────────
    const Product(
      id: 'm1',
      name: 'Urban Oversized Tee',
      category: 'Men',
      price: 990,
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600',
      description: 'A relaxed oversized tee perfect for everyday streetwear. Made from 100% organic cotton.',
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      isFeatured: true,
      colorOptions: [
        ProductColor(name: 'White',  color: Color(0xFFF5F5F5), imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600'),
        ProductColor(name: 'Olive',  color: Color(0xFF5C6B4A), imageUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600'),
        ProductColor(name: 'Navy',   color: Color(0xFF1B2A4A), imageUrl: 'https://images.unsplash.com/photo-1582552938357-32b906df40cb?w=600'),
      ],
    ),
    const Product(
      id: 'm2',
      name: 'Slim Fit Chinos',
      category: 'Men',
      price: 1815,
      imageUrl: 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600',
      description: 'Modern slim fit chinos with a clean tapered cut.',
      sizes: ['S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Khaki',  color: Color(0xFFC3B091), imageUrl: 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600'),
        ProductColor(name: 'Grey',   color: Color(0xFF888780), imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600'),
      ],
    ),
    const Product(
      id: 'm3',
      name: 'Technical Bomber Jacket',
      category: 'Men',
      price: 2970,
      imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600',
      description: 'A lightweight technical bomber with water-resistant finish.',
      sizes: ['S', 'M', 'L', 'XL'],
      isFeatured: true,
      colorOptions: [
        ProductColor(name: 'Olive',  color: Color(0xFF5C6B4A), imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=600'),
        ProductColor(name: 'Navy',   color: Color(0xFF1B2A4A), imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=600'),
      ],
    ),
    const Product(
      id: 'm4',
      name: 'Cargo Utility Pants',
      category: 'Men',
      price: 2145,
      imageUrl: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600',
      description: 'Trending cargo pants with multiple utility pockets.',
      sizes: ['S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Beige',  color: Color(0xFFD4C5A9), imageUrl: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600'),
        ProductColor(name: 'Olive',  color: Color(0xFF5C6B4A), imageUrl: 'https://images.unsplash.com/photo-1562183241-b937e95585b6?w=600'),
      ],
    ),
    const Product(
      id: 'm5',
      name: 'Merino Knit Sweater',
      category: 'Men',
      price: 2475,
      imageUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600',
      description: 'Ultra-soft merino wool sweater with a modern ribbed texture.',
      sizes: ['S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Camel',  color: Color(0xFFC19A6B), imageUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600'),
        ProductColor(name: 'Grey',   color: Color(0xFF888780), imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600'),
      ],
    ),
    const Product(
      id: 'm6',
      name: 'Relaxed Linen Shirt',
      category: 'Men',
      price: 1485,
      imageUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600',
      description: 'Breezy linen shirt with a relaxed fit.',
      sizes: ['S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'White',  color: Color(0xFFF5F5F5), imageUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600'),
        ProductColor(name: 'Blue',   color: Color(0xFF378ADD), imageUrl: 'https://images.unsplash.com/photo-1512353087810-25dfcd100962?w=600'),
        ProductColor(name: 'Beige',  color: Color(0xFFD4C5A9), imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600'),
      ],
    ),

    // ── Dresses ─────────────────────────────────────────────────────────────
    const Product(
      id: 'd1',
      name: 'Velvet Night Gown',
      category: 'Women',
      price: 3250,
      imageUrl: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=600',
      description: 'A luxurious velvet night gown with a floor-length silhouette. Perfect for formal evening events.',
      sizes: ['S', 'M', 'L'],
      isFeatured: true,
      colorOptions: [
        ProductColor(name: 'Emerald', color: Color(0xFF046307), imageUrl: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=600'),
        ProductColor(name: 'Midnight', color: Color(0xFF191970), imageUrl: 'https://images.unsplash.com/photo-1539008835270-aa9473df9175?w=600'),
        ProductColor(name: 'Burgundy', color: Color(0xFF800020), imageUrl: 'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?w=600'),
      ],
    ),
    const Product(
      id: 'd2',
      name: 'Silk Slip Midi',
      category: 'Women',
      price: 2400,
      imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600',
      description: 'Elegant silk slip dress with a midi cut and delicate adjustable straps.',
      sizes: ['XS', 'S', 'M', 'L'],
      isFeatured: true,
      colorOptions: [
        ProductColor(name: 'Champagne', color: Color(0xFFF7E7CE), imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600'),
        ProductColor(name: 'Rose', color: Color(0xFFE8A0B4), imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600'),
      ],
    ),
    const Product(
      id: 'd3',
      name: 'Bohemian Maxi Dress',
      category: 'Women',
      price: 1850,
      imageUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600',
      description: 'A breezy bohemian maxi dress with intricate floral embroidery.',
      sizes: ['S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Floral', color: Color(0xFFE8A0B4), imageUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600'),
        ProductColor(name: 'Sky Blue', color: Color(0xFF87CEEB), imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600'),
      ],
    ),

    const Product(
      id: 'w1',
      name: 'Flowy Midi Dress',
      category: 'Women',
      price: 1980,
      imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600',
      description: 'An elegant flowy midi dress. Perfect for all occasions.',
      sizes: ['XS', 'S', 'M', 'L'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Floral', color: Color(0xFFE8A0B4), imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=600'),
      ],
    ),

    // ── Women ─────────────────────────────────────────────────────────────────

    const Product(
      id: 'w3',
      name: 'Wide Leg Trousers',
      category: 'Women',
      price: 1650,
      imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
      description: 'Trendy wide leg trousers with a high waist.',
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Beige',  color: Color(0xFFD4C5A9), imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600'),
        ProductColor(name: 'White',  color: Color(0xFFF5F5F5), imageUrl: 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=600'),
      ],
    ),

    const Product(
      id: 'w5',
      name: 'Oversized Denim Jacket',
      category: 'Women',
      price: 2805,
      imageUrl: 'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=600',
      description: 'Classic oversized denim jacket with a vintage wash.',
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Light Blue', color: Color(0xFF85B7EB), imageUrl: 'https://images.unsplash.com/photo-1551489186-cf8726f514f8?w=600'),
        ProductColor(name: 'Dark Blue',  color: Color(0xFF185FA5), imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=600'),
        ProductColor(name: 'Black',      color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1548126032-079a0fb0099d?w=600'),
      ],
    ),
    const Product(
      id: 'w6',
      name: 'Satin Slip Skirt',
      category: 'Women',
      price: 1485,
      imageUrl: 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=600',
      description: 'Luxurious satin slip skirt with a bias cut.',
      sizes: ['XS', 'S', 'M', 'L'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Champagne', color: Color(0xFFE8D5B7), imageUrl: 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=600'),
        ProductColor(name: 'Black',     color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600'),
        ProductColor(name: 'Blush',     color: Color(0xFFE8A0B4), imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600'),
        ProductColor(name: 'Forest',    color: Color(0xFF3B6D11), imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600'),
      ],
    ),

    // ── Kids ──────────────────────────────────────────────────────────────────
    const Product(
      id: 'k1',
      name: 'Colourful Hoodie',
      category: 'Kids',
      price: 1090,
      imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600',
      description: 'A fun and cosy hoodie for kids in vibrant colours.',
      sizes: ['3-4Y', '5-6Y', '7-8Y', '9-10Y'],
      isFeatured: true,
      colorOptions: [
        ProductColor(name: 'Red',    color: Color(0xFFE24B4A), imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600'),
        ProductColor(name: 'Blue',   color: Color(0xFF378ADD), imageUrl: 'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=600'),
        ProductColor(name: 'Yellow', color: Color(0xFFEF9F27), imageUrl: 'https://images.unsplash.com/photo-1476234251651-f353703a034d?w=600'),
        ProductColor(name: 'Green',  color: Color(0xFF639922), imageUrl: 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=600'),
      ],
    ),
    const Product(
      id: 'k2',
      name: 'Denim Dungarees',
      category: 'Kids',
      price: 1285,
      imageUrl: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=600',
      description: 'Adorable denim dungarees with adjustable straps.',
      sizes: ['3-4Y', '5-6Y', '7-8Y', '9-10Y'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Light Blue', color: Color(0xFF85B7EB), imageUrl: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=600'),
        ProductColor(name: 'Dark Blue',  color: Color(0xFF185FA5), imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600'),
      ],
    ),
    const Product(
      id: 'k3',
      name: 'Graphic Print Tee',
      category: 'Kids',
      price: 660,
      imageUrl: 'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=600',
      description: 'Fun graphic print tee made from 100% organic cotton.',
      sizes: ['3-4Y', '5-6Y', '7-8Y', '9-10Y', '11-12Y'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'White',  color: Color(0xFFF5F5F5), imageUrl: 'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=600'),
        ProductColor(name: 'Yellow', color: Color(0xFFEF9F27), imageUrl: 'https://images.unsplash.com/photo-1476234251651-f353703a034d?w=600'),
        ProductColor(name: 'Blue',   color: Color(0xFF378ADD), imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600'),
      ],
    ),
    const Product(
      id: 'k4',
      name: 'Fleece Zip-Up Jacket',
      category: 'Kids',
      price: 1420,
      imageUrl: 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=600',
      description: 'Warm and lightweight fleece zip-up jacket.',
      sizes: ['3-4Y', '5-6Y', '7-8Y', '9-10Y'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Grey',  color: Color(0xFF888780), imageUrl: 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=600'),
        ProductColor(name: 'Navy',  color: Color(0xFF1B2A4A), imageUrl: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=600'),
        ProductColor(name: 'Red',   color: Color(0xFFE24B4A), imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600'),
      ],
    ),
    const Product(
      id: 'k5',
      name: 'Jogger Set',
      category: 'Kids',
      price: 1190,
      imageUrl: 'https://images.unsplash.com/photo-1476234251651-f353703a034d?w=600',
      description: 'Matching jogger set with elastic waistband.',
      sizes: ['3-4Y', '5-6Y', '7-8Y', '9-10Y', '11-12Y'],
      isFeatured: true,
      colorOptions: [
        ProductColor(name: 'Grey',  color: Color(0xFF888780), imageUrl: 'https://images.unsplash.com/photo-1476234251651-f353703a034d?w=600'),
        ProductColor(name: 'Black', color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=600'),
        ProductColor(name: 'Blue',  color: Color(0xFF378ADD), imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600'),
      ],
    ),

    // ── Others ────────────────────────────────────────────────────────────────
    const Product(
      id: 'o1',
      name: 'Canvas Tote Bag',
      category: 'Others',
      price: 8250,
      imageUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=600',
      description: 'A sturdy canvas tote bag with zip closure.',
      sizes: ['One Size'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Natural', color: Color(0xFFD4C5A9), imageUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=600'),
        ProductColor(name: 'Black',   color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600'),
        ProductColor(name: 'Olive',   color: Color(0xFF5C6B4A), imageUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600'),
      ],
    ),
    const Product(
      id: 'o2',
      name: 'Knit Beanie',
      category: 'Others',
      price: 6300,
      imageUrl: 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600',
      description: 'Classic ribbed knit beanie in neutral tones.',
      sizes: ['One Size'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Grey',   color: Color(0xFF888780), imageUrl: 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600'),
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600'),
        ProductColor(name: 'Camel',  color: Color(0xFFC19A6B), imageUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600'),
        ProductColor(name: 'Red',    color: Color(0xFFE24B4A), imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600'),
      ],
    ),
    const Product(
      id: 'o3',
      name: 'Leather Belt',
      category: 'Others',
      price: 9900,
      imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
      description: 'Premium leather belt with a minimalist buckle.',
      sizes: ['S', 'M', 'L', 'XL'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Brown', color: Color(0xFF8B5E3C), imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600'),
        ProductColor(name: 'Black', color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=600'),
        ProductColor(name: 'Tan',   color: Color(0xFFC19A6B), imageUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600'),
      ],
    ),
    const Product(
      id: 'o4',
      name: 'Wool Scarf',
      category: 'Others',
      price: 11550,
      imageUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600',
      description: 'Soft wool scarf in classic plaid pattern.',
      sizes: ['One Size'],
      isFeatured: true,
      colorOptions: [
        ProductColor(name: 'Plaid',  color: Color(0xFFA32D2D), imageUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600'),
        ProductColor(name: 'Grey',   color: Color(0xFF888780), imageUrl: 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600'),
        ProductColor(name: 'Camel',  color: Color(0xFFC19A6B), imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600'),
      ],
    ),
    const Product(
      id: 'o5',
      name: 'Sport Snapback Cap',
      category: 'Others',
      price: 7600,
      imageUrl: 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=600',
      description: 'Trending snapback cap with embroidered logo.',
      sizes: ['One Size'],
      isFeatured: false,
      colorOptions: [
        ProductColor(name: 'Black',  color: Color(0xFF1A1A1A), imageUrl: 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=600'),
        ProductColor(name: 'White',  color: Color(0xFFF5F5F5), imageUrl: 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600'),
        ProductColor(name: 'Navy',   color: Color(0xFF1B2A4A), imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600'),
        ProductColor(name: 'Red',    color: Color(0xFFE24B4A), imageUrl: 'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=600'),
      ],
    ),
  ];
}