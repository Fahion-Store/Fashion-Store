import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/cart_provider.dart';

class ProductListingScreen extends StatefulWidget {
  final String category;
  const ProductListingScreen({super.key, required this.category});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  late String _selectedCategory;
  String _sortBy = 'default';
  
  final List<String> _categories = [
    'All',
    'Men',
    'Women',
    'Kids',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category == 'All' ? 'All' : widget.category;
    
    // Fetch products if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (provider.products.isEmpty) {
        provider.fetchProducts();
      }
    });
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort Products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildSortOption('Default', 'default'),
              _buildSortOption('Price: Low to High', 'priceLowHigh'),
              _buildSortOption('Price: High to Low', 'priceHighLow'),
              _buildSortOption('Highest Customer Rating', 'rating'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.accent : AppColors.dark,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.accent) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = List<Product>.from(
          provider.getProductsByCategory(_selectedCategory)
        );

        if (_sortBy == 'priceLowHigh') {
          products.sort((a, b) => a.price.compareTo(b.price));
        } else if (_sortBy == 'priceHighLow') {
          products.sort((a, b) => b.price.compareTo(a.price));
        } else if (_sortBy == 'rating') {
          products.sort((a, b) => b.displayRating.compareTo(a.displayRating));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () => context.go('/home'),
            ),
            title: Text(widget.category.toUpperCase()),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () => context.push('/wishlist'),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.go('/cart'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category filter chips ──────────────────────────────────────
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final selected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.dark : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.dark
                                : AppColors.lightGrey,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: selected
                                    ? AppColors.background
                                    : AppColors.dark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Count + filters row ────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${products.length} Products',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    GestureDetector(
                      onTap: _showSortBottomSheet,
                      child: Row(
                        children: [
                          Icon(Icons.tune,
                              size: 16, color: AppColors.mediumGrey),
                          const SizedBox(width: 4),
                          Text(
                            'Sort / Filter',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Product grid ───────────────────────────────────────────────
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'No products found.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchProducts(forceRefresh: true),
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.70,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, i) => _ProductGridCard(
                            product: products[i],
                            onTap: () =>
                                context.push('/products/${products[i].id}'),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Product grid card ─────────────────────────────────────────────────────────
class _ProductGridCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.onTap});

  @override
  State<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<_ProductGridCard> {
  @override
  Widget build(BuildContext context) {
    final discount = widget.product.discountPercentage;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + wishlist button ──────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.lightGrey,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.lightGrey,
                        child: Icon(Icons.image_outlined,
                            color: AppColors.mediumGrey),
                      ),
                    ),
                  ),
                  // Wishlist button
                  Consumer<WishlistProvider>(
                    builder: (context, wishlist, _) {
                      final isWishlisted = wishlist.isWishlisted(widget.product.id);
                      return Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => wishlist.toggleWishlist(widget.product),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: isWishlisted
                                  ? AppColors.heartActive
                                  : AppColors.mediumGrey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Discount Badge
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Quick add to cart button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        return GestureDetector(
                          onTap: () {
                            cart.addItem(widget.product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.product.name} added to cart!'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.dark,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_shopping_cart,
                              size: 15,
                              color: AppColors.background,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Details ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: AppTextStyles.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Rating Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.product.displayRating}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${widget.product.displayReviewCount})',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (discount > 0)
                            Text(
                              'Rs. ${widget.product.displayOriginalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.mediumGrey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            'Rs. ${widget.product.price.toStringAsFixed(0)}',
                            style: AppTextStyles.productPrice,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}