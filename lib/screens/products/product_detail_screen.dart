import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/common_app_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/product_color.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/services/database_service.dart';
import '../../models/review_model.dart';
import '../../providers/theme_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  int _selectedColorIndex = 0;
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  int _galleryIndex = 0;
  PageController? _galleryController;

  Product? get _product {
    final products = Provider.of<ProductProvider>(context, listen: false).products;
    return products.where((p) => p.id == widget.productId).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
    _fetchReviews();
    
    // Add to recently viewed on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_product != null) {
        Provider.of<ProductProvider>(context, listen: false)
            .addToRecentlyViewed(widget.productId);
      }
    });
  }

  @override
  void dispose() {
    _galleryController?.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    final reviews = await DatabaseService().getProductReviews(widget.productId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _showAddReviewDialog() async {
    final userProv = context.read<UserProvider>();
    if (!userProv.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review')),
      );
      return;
    }

    final commentCtrl = TextEditingController();
    double rating = 5.0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1.0),
                  );
                }),
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final review = Review(
                  id: '',
                  userId: userProv.user!.uid,
                  productId: widget.productId,
                  userName: userProv.displayName,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                  date: DateTime.now(),
                );
                await DatabaseService().addReview(review);
                if (context.mounted) {
                  Navigator.pop(context);
                  _fetchReviews();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    final product = _product;
    if (product == null) return;
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a size'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    context.read<CartProvider>().addItem(product, size: _selectedSize);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  void _showSizeGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Size Guide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Standard clothing size measurements (in inches):'),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: AppColors.lightGrey),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppColors.surface),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Chest', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Waist', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('S')),
                      Padding(padding: EdgeInsets.all(8), child: Text('34-36')),
                      Padding(padding: EdgeInsets.all(8), child: Text('28-30')),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('M')),
                      Padding(padding: EdgeInsets.all(8), child: Text('38-40')),
                      Padding(padding: EdgeInsets.all(8), child: Text('32-34')),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('L')),
                      Padding(padding: EdgeInsets.all(8), child: Text('42-44')),
                      Padding(padding: EdgeInsets.all(8), child: Text('36-38')),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('XL')),
                      Padding(padding: EdgeInsets.all(8), child: Text('46-48')),
                      Padding(padding: EdgeInsets.all(8), child: Text('40-42')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final product = _product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => context.go('/products'))),
        body: const Center(child: Text('Product not found')),
      );
    }

    final discount = product.discountPercentage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: product.name,
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing link to "${product.name}"!'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Swipeable image gallery ──────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 400,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _galleryController,
                    onPageChanged: (idx) => setState(() => _galleryIndex = idx),
                    itemCount: product.displayGalleryImages.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: product.displayGalleryImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => Container(
                          color: AppColors.lightGrey,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.lightGrey,
                          child: Icon(Icons.image_outlined, color: AppColors.mediumGrey, size: 48),
                        ),
                      );
                    },
                  ),
                  // Page dots indicator
                  if (product.displayGalleryImages.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.displayGalleryImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _galleryIndex == index ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _galleryIndex == index
                                  ? AppColors.dark
                                  : AppColors.mediumGrey.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Price Row
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rs. ${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Rs. ${product.displayOriginalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mediumGrey,
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Star rating average preview
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${product.displayRating}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.displayReviewCount} Ratings)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(product.category, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(product.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),

                  // ── Color selector ─────────────────────────────────────
                  if (product.colorOptions.isNotEmpty) ...[
                    Row(
                      children: [
                        Text('Color', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(width: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            product.colorOptions[_selectedColorIndex].name,
                            key: ValueKey(_selectedColorIndex),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.dark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(
                        product.colorOptions.length,
                        (i) => _ColorSwatch(
                          productColor: product.colorOptions[i],
                          isSelected: i == _selectedColorIndex,
                          onTap: () {
                            setState(() {
                              _selectedColorIndex = i;
                              // Switch gallery page to color image if matches
                              final colorImg = product.colorOptions[i].imageUrl;
                              final imgIdx = product.displayGalleryImages.indexOf(colorImg);
                              if (imgIdx != -1 && _galleryController != null && _galleryController!.hasClients) {
                                _galleryController!.animateToPage(
                                  imgIdx,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Size selector ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Size', style: Theme.of(context).textTheme.labelLarge),
                      TextButton(
                        onPressed: _showSizeGuideDialog,
                        style: TextButton.styleFrom(foregroundColor: AppColors.mediumGrey, padding: EdgeInsets.zero),
                        child: Text('Size guide', style: Theme.of(context).textTheme.labelMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.sizes.map((size) {
                      final selected = size == _selectedSize;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.dark : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? AppColors.dark : AppColors.lightGrey),
                          ),
                          child: Text(
                            size,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: selected ? AppColors.background : AppColors.dark),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── You May Also Like ──────────────────────────────────
                  const Divider(height: 48),
                  Text('You May Also Like', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 210,
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        final related = provider.products
                            .where((p) => p.category == product.category && p.id != product.id)
                            .toList();
                        
                        if (related.isEmpty) {
                          return const Center(child: Text('No similar products found.'));
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: related.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, i) {
                            final relatedProd = related[i];
                            return GestureDetector(
                              onTap: () {
                                context.push('/products/${relatedProd.id}');
                              },
                              child: Container(
                                width: 130,
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                        child: CachedNetworkImage(
                                          imageUrl: relatedProd.imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            relatedProd.name,
                                            style: AppTextStyles.productName.copyWith(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Rs. ${relatedProd.price.toStringAsFixed(0)}',
                                            style: AppTextStyles.productPrice.copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Reviews Section ─────────────────────────────────────
                  const Divider(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reviews (${_reviews.length})', style: Theme.of(context).textTheme.headlineSmall),
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.add_comment_outlined, size: 18),
                        label: const Text('Write a Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    const Text('No reviews yet. Be the first to review!')
                  else
                    ..._reviews.map((review) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.lightGrey,
                                    child: Text(review.userName.isNotEmpty ? review.userName.substring(0, 1).toUpperCase() : '?'),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(review.userName, style: Theme.of(context).textTheme.labelLarge),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < review.rating ? Icons.star : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        )),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.lightGrey)),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSize,
                  hint: Text('Size', style: Theme.of(context).textTheme.bodyMedium),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  items: product.sizes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: Theme.of(context).textTheme.bodyLarge))).toList(),
                  onChanged: (v) => setState(() => _selectedSize = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Add to Cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final ProductColor productColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({required this.productColor, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: productColor.name,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: productColor.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.dark : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: productColor.color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: productColor.color.computeLuminance() > 0.5 ? AppColors.dark : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}