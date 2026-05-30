import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import '../../providers/theme_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final items = cart.items.values.toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              children: [
                const Text('My Cart'),
                Text(
                  '${cart.itemCount} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () => cart.clearCart(),
                  child: Text(
                    'Clear all',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: items.isEmpty
              ? _EmptyCart()
              : Column(
                  children: [
                    // ── Cart items list ──────────────────────────────────
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _CartItemCard(item: items[i]),
                      ),
                    ),

                    // ── Upgrades: Progress Bar & Coupon Box ──────────────
                    _ShippingProgressBar(subtotal: cart.totalPrice),
                    _PromoCodeInput(cart: cart),

                    // ── Order summary ────────────────────────────────────
                    _OrderSummary(cart: cart),
                  ],
                ),
        );
      },
    );
  }
}

// ── Empty cart ────────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 44,
              color: AppColors.mediumGrey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () => context.go('/products'),
              child: const Text('Shop Now'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart item card ────────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.lightGrey),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.lightGrey,
                child: Icon(Icons.image_outlined,
                    color: AppColors.mediumGrey),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.selectedSize != null)
                  Text(
                    'Size: ${item.selectedSize}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                Text(
                  'Rs. ${item.product.price.toStringAsFixed(0)}',
                  style: AppTextStyles.productPrice,
                ),
              ],
            ),
          ),

          // Quantity controls + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Delete button
              GestureDetector(
                onTap: () => cart.removeItem(item.id),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.mediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              // Quantity row
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: () =>
                        cart.updateQuantity(item.id, item.quantity - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: () =>
                        cart.updateQuantity(item.id, item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quantity button ───────────────────────────────────────────────────────────
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Icon(icon, size: 14, color: AppColors.dark),
      ),
    );
  }
}

// ── Shipping Progress Bar ─────────────────────────────────────────────────────
class _ShippingProgressBar extends StatelessWidget {
  final double subtotal;
  const _ShippingProgressBar({required this.subtotal});

  @override
  Widget build(BuildContext context) {
    const double target = 2000.0;
    final double diff = target - subtotal;
    final double progress = (subtotal / target).clamp(0.0, 1.0);
    final isFree = diff <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFree ? 'FREE Shipping Unlocked! 🎉' : 'Shipping Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFree ? Colors.green : AppColors.dark,
                ),
              ),
              if (!isFree)
                Text(
                  'Add Rs. ${diff.toStringAsFixed(0)} more for FREE shipping',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mediumGrey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFree ? Colors.green : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promo Code Box ────────────────────────────────────────────────────────────
class _PromoCodeInput extends StatefulWidget {
  final CartProvider cart;
  const _PromoCodeInput({required this.cart});

  @override
  State<_PromoCodeInput> createState() => _PromoCodeInputState();
}

class _PromoCodeInputState extends State<_PromoCodeInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCoupon = widget.cart.couponCode.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: hasCoupon
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer_outlined, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Coupon "${widget.cart.couponCode}" applied!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    widget.cart.removeCoupon();
                    _ctrl.clear();
                  },
                  child: Text(
                    'Remove',
                    style: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter Promo Code (e.g. FIRST20)',
                      hintStyle: TextStyle(fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final applied = widget.cart.applyCoupon(_ctrl.text.trim());
                    if (applied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Promo code applied successfully!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid promo code. Try "FIRST20"'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(60, 36),
                    backgroundColor: AppColors.dark,
                  ),
                  child: const Text('Apply', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
    );
  }
}

// ── Order summary ─────────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.lightGrey, width: 1),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
          if (cart.couponCode.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Discount (20%)',
              value: '-Rs. ${cart.discountAmount.toStringAsFixed(0)}',
            ),
          ],
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Shipping',
            value: cart.shippingCost == 0.0 ? 'FREE' : 'Rs. ${cart.shippingCost.toStringAsFixed(0)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _SummaryRow(
            label: 'Total',
            value: 'Rs. ${cart.finalTotal.toStringAsFixed(0)}',
            bold: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/checkout'),
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}