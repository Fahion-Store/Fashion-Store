import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/cart_provider.dart';
import 'dart:async';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  int _selectedCategoryIndex = 0;

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Men',    'icon': Icons.man_outlined},
    {'label': 'Women',  'icon': Icons.woman_outlined},
    {'label': 'Kids',   'icon': Icons.child_care_outlined},
    {'label': 'Others', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Fetch products from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }


  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<Product> _getFeaturedProducts(ProductProvider provider) =>
      provider.featuredProducts;

  List<Product> _getFilteredProducts(ProductProvider provider) {
    final cat = _categories[_selectedCategoryIndex]['label'] as String;
    return provider.getProductsByCategory(cat).take(4).toList();
  }


  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 100)),

            // ── Hero editorial banner ────────────────────────────────────
            SliverToBoxAdapter(child: _HeroBanner()),

            // ── Season tag line ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'NEW ARRIVALS  •  SS 2026',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Outfit set dark CTA ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _OutfitCTA(),
              ),
            ),

            // ── Category tabs ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Shop by Category',
                          style: AppTextStyles.sectionTitle),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final selected = i == _selectedCategoryIndex;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategoryIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.dark
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.dark
                                      : AppColors.lightGrey,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _categories[i]['icon'] as IconData,
                                    size: 14,
                                    color: selected
                                        ? AppColors.background
                                        : AppColors.dark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _categories[i]['label'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? AppColors.background
                                          : AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category products grid ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _categories[_selectedCategoryIndex]['label'] as String,
                        key: ValueKey(_selectedCategoryIndex),
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(
                          '/products?category=${_categories[_selectedCategoryIndex]['label']}'),
                      child: Row(
                        children: [
                          Text('See all',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mediumGrey,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios,
                              size: 11, color: AppColors.mediumGrey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.products.isEmpty) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final filtered = _getFilteredProducts(provider);
                  if (filtered.isEmpty) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: Text('No products found')),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      key: ValueKey(_selectedCategoryIndex),
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => _PremiumProductCard(
                          product: filtered[i],
                          onTap: () => context
                              .go('/products/${filtered[i].id}'),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Featured full-width editorial card ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: _EditorialCard(),
              ),
            ),

            // ── Trending now row ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Text('Trending Now', style: AppTextStyles.sectionTitle),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  final featured = _getFeaturedProducts(provider);
                  if (featured.isEmpty) return const SizedBox();

                  return SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) => _PremiumProductCard(
                        product: featured[i],
                        onTap: () =>
                            context.go('/products/${featured[i].id}'),
                        showBadge: true,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Recently viewed row ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  final recentlyViewed = provider.recentlyViewedProducts;
                  if (recentlyViewed.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Text('Recently Viewed', style: AppTextStyles.sectionTitle),
                      ),
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          itemCount: recentlyViewed.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, i) => _PremiumProductCard(
                            product: recentlyViewed[i],
                            onTap: () =>
                                context.push('/products/${recentlyViewed[i].id}'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 24,
      title: Text(
        'XAN OWNS',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 5,
          color: AppColors.dark,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 22),
          onPressed: () {
            showSearch(
              context: context,
              delegate: ProductSearchDelegate(
                Provider.of<ProductProvider>(context, listen: false).products,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, size: 22),
          onPressed: () => context.push('/wishlist'),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, size: 22),
              onPressed: () => context.go('/cart'),
            ),
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Hero editorial banner ─────────────────────────────────────────────────────
// ── Hero editorial banner carousel ───────────────────────────────────────────
class _HeroBanner extends StatefulWidget {
  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  late final PageController _pageController;
  late final Timer _timer;
  int _currentPage = 0;

  final List<Map<String, String>> _banners = [
    {
      'image': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900',
      'tag': 'NEW SEASON',
      'title': 'Explore New\nCollection',
    },
    {
      'image': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=900',
      'tag': 'SUMMER SALE',
      'title': 'Up to 30% Off\nSelected Styles',
    },
    {
      'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=900',
      'tag': 'STREETWEAR',
      'title': 'Urban Cargo\nEssentials',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _banners.length,
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: banner['image']!,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.42),
                          colorBlendMode: BlendMode.darken,
                          placeholder: (_, __) =>
                              Container(color: const Color(0xFF1A1E16)),
                          errorWidget: (_, __, ___) =>
                              Container(color: const Color(0xFF1A1E16)),
                        ),
                      ),
                      // Gradient overlay bottom
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        left: 24, right: 24, bottom: 24,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      banner['tag']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    banner['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/products'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Shop',
                                      style: TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward,
                                        size: 14, color: Color(0xFF1A1A1A)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Pagination Dots
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _banners.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
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
    );
  }
}

// ── Outfit CTA ────────────────────────────────────────────────────────────────
class _OutfitCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/products'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.style_outlined,
                  size: 20, color: AppColors.background),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personal Outfit Set',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Curated looks just for you',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: AppColors.mediumGrey),
          ],
        ),
      ),
    );
  }
}

// ── Editorial full-width card ─────────────────────────────────────────────────
class _EditorialCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/products?category=Women'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 160,
          color: const Color(0xFF2C2420),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800',
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.38),
                  colorBlendMode: BlendMode.darken,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF2C2420)),
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFF2C2420)),
                ),
              ),
              Positioned(
                left: 20, top: 20, bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WOMEN\'S EDIT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Effortless\nElegance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Explore →',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Premium product card ──────────────────────────────────────────────────────
class _PremiumProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showBadge;

  const _PremiumProductCard({
    required this.product,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  State<_PremiumProductCard> createState() => _PremiumProductCardState();
}

class _PremiumProductCardState extends State<_PremiumProductCard> {

  @override
  Widget build(BuildContext context) {
    final discount = widget.product.discountPercentage;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + overlay buttons
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.lightGrey,
                        child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.lightGrey,
                        child: Icon(Icons.image_outlined,
                            color: AppColors.mediumGrey),
                      ),
                    ),
                  ),
                  // Top badges row
                  Positioned(
                    top: 8, left: 8, right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.showBadge)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.dark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TRENDING',
                              style: TextStyle(
                                color: AppColors.background,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          )
                        else if (discount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
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
                          )
                        else
                          const SizedBox(),
                        Consumer<WishlistProvider>(
                          builder: (context, wishlist, _) {
                            final isWishlisted = wishlist.isWishlisted(widget.product.id);
                            return GestureDetector(
                              onTap: () => wishlist.toggleWishlist(widget.product),
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 15,
                                  color: isWishlisted
                                      ? AppColors.heartActive
                                      : AppColors.mediumGrey,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: AppTextStyles.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
                      // Color dots preview
                      if (widget.product.colorOptions.isNotEmpty)
                        Row(
                          children: widget.product.colorOptions
                              .take(2)
                              .map((c) => Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(left: 3),
                                    decoration: BoxDecoration(
                                      color: c.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.lightGrey,
                                        width: 0.5,
                                      ),
                                    ),
                                  ))
                              .toList(),
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

// ── Search Delegate ───────────────────────────────────────────────────────────
class ProductSearchDelegate extends SearchDelegate<String?> {
  final List<Product> products;

  ProductSearchDelegate(this.products);

  @override
  String get searchFieldLabel => 'Search products...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = products.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase()) ||
             p.category.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: CachedNetworkImage(
            imageUrl: product.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.lightGrey),
            errorWidget: (_, __, ___) => const Icon(Icons.image),
          ),
          title: Text(product.name),
          subtitle: Text('Rs. ${product.price.toStringAsFixed(0)}'),
          onTap: () {
            close(context, null);
            context.push('/products/${product.id}');
          },
        );
      },
    );
  }
}