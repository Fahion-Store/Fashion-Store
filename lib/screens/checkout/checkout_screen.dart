import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_app_bar.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/address_provider.dart';
import '../../core/services/database_service.dart';
import '../../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  String _selectedPayment = 'card';

  // Delivery form controllers
  final _fullNameCtrl    = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _cityCtrl        = TextEditingController();
  final _postalCtrl      = TextEditingController();
  final _countryCtrl     = TextEditingController();

  // Payment form controllers
  final _cardNumCtrl     = TextEditingController();
  final _expiryCtrl      = TextEditingController();
  final _cvvCtrl         = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _countryCtrl.dispose();
    _cardNumCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final userProv = context.read<UserProvider>();
    final db = DatabaseService();

    if (userProv.user == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final order = OrderModel(
      id: '', // Will be set by Firestore
      userId: userProv.user!.uid,
      items: cart.items.values.toList(),
      totalAmount: cart.finalTotal,
      date: DateTime.now(),
      shippingDetails: {
        'fullName': _fullNameCtrl.text,
        'phone': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'city': _cityCtrl.text,
        'postalCode': _postalCtrl.text,
        'country': _countryCtrl.text,
      },
      paymentMethod: _selectedPayment,
    );

    final orderId = await db.placeOrder(order);

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (orderId != null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 36, color: AppColors.accent),
                  ),
                  const SizedBox(height: 20),
                  Text('Order Placed!',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Your order has been placed successfully. Order ID: $orderId',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        cart.clearCart();
                        Navigator.pop(context);
                        context.go('/home');
                      },
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final double shipping = cart.shippingCost;
    final double total = cart.finalTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'Checkout',
        showBack: true,
        onBackPressed: () => context.go('/cart'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Step indicators ──────────────────────────────────────────
            _StepIndicator(currentStep: _currentStep),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _DeliveryForm(
                        fullNameCtrl: _fullNameCtrl,
                        phoneCtrl: _phoneCtrl,
                        addressCtrl: _addressCtrl,
                        cityCtrl: _cityCtrl,
                        postalCtrl: _postalCtrl,
                        countryCtrl: _countryCtrl,
                      )
                    : _currentStep == 1
                        ? _PaymentForm(
                            selected: _selectedPayment,
                            onChanged: (v) =>
                                setState(() => _selectedPayment = v),
                            cardNumCtrl: _cardNumCtrl,
                            expiryCtrl: _expiryCtrl,
                            cvvCtrl: _cvvCtrl,
                          )
                        : _OrderReview(
                            cart: cart,
                            shipping: shipping,
                            fullName: _fullNameCtrl.text,
                            address: _addressCtrl.text,
                            city: _cityCtrl.text,
                            phone: _phoneCtrl.text,
                            paymentMethod: _selectedPayment,
                            cardNumber: _cardNumCtrl.text,
                          ),
              ),
            ),

            // ── Bottom action ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.lightGrey),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _currentStep--),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep < 2) {
                            if (_currentStep == 0 &&
                                !_formKey.currentState!.validate()) {
                              return;
                            }
                            setState(() => _currentStep++);
                          } else {
                            _placeOrder();
                          }
                        },
                        child: Text(
                          _currentStep == 2
                              ? 'Place Order  •  Rs. ${total.toStringAsFixed(0)}'
                              : 'Continue',
                        ),
                      ),
                    ),
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

// ── Step indicator ────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const steps = ['Delivery', 'Payment', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep
                    ? AppColors.dark
                    : AppColors.lightGrey,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone || isActive
                      ? AppColors.dark
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDone || isActive
                        ? AppColors.dark
                        : AppColors.lightGrey,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check, size: 16, color: AppColors.background)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.background
                                : AppColors.mediumGrey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive || isDone
                          ? AppColors.dark
                          : AppColors.mediumGrey,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Delivery form ─────────────────────────────────────────────────────────────
class _DeliveryForm extends StatefulWidget {
  final TextEditingController fullNameCtrl, phoneCtrl, addressCtrl,
      cityCtrl, postalCtrl, countryCtrl;

  const _DeliveryForm({
    required this.fullNameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.postalCtrl,
    required this.countryCtrl,
  });

  @override
  State<_DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<_DeliveryForm> {
  String? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    final addressProv = context.watch<AddressProvider>();
    final addresses = addressProv.addresses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (addresses.isNotEmpty) ...[
          Text('Saved Addresses',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                final isSelected = _selectedAddressId == address.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAddressId = address.id;
                    });
                    widget.addressCtrl.text = address.street;
                    widget.cityCtrl.text = address.city;
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.dark : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.dark : AppColors.lightGrey,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              address.label.toLowerCase() == 'home'
                                  ? Icons.home_outlined
                                  : address.label.toLowerCase() == 'office'
                                      ? Icons.work_outline
                                      : Icons.location_on_outlined,
                              size: 16,
                              color: isSelected ? AppColors.background : AppColors.dark,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                address.label,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: isSelected ? AppColors.background : AppColors.dark,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: AppColors.background, size: 14),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.street,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected ? AppColors.background.withValues(alpha: 0.7) : AppColors.mediumGrey,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          address.city,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected ? AppColors.background.withValues(alpha: 0.7) : AppColors.mediumGrey,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text('Delivery Details',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        _Field(label: 'Full Name', controller: widget.fullNameCtrl,
            hint: 'John Doe', icon: Icons.person_outline),
        const SizedBox(height: 16),
        _Field(label: 'Phone Number', controller: widget.phoneCtrl,
            hint: '+1 234 567 890', icon: Icons.phone_outlined,
            type: TextInputType.phone),
        const SizedBox(height: 16),
        _Field(label: 'Address', controller: widget.addressCtrl,
            hint: '123 Main Street', icon: Icons.home_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Field(label: 'City', controller: widget.cityCtrl,
                  hint: 'Colombo', icon: Icons.location_city_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(label: 'Postal Code', controller: widget.postalCtrl,
                  hint: '10000', icon: Icons.local_post_office_outlined,
                  type: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Field(label: 'Country', controller: widget.countryCtrl,
            hint: 'Sri Lanka', icon: Icons.flag_outlined),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType type;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }
}

// ── Payment form ──────────────────────────────────────────────────────────────
class _PaymentForm extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final TextEditingController cardNumCtrl, expiryCtrl, cvvCtrl;

  const _PaymentForm({
    required this.selected,
    required this.onChanged,
    required this.cardNumCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        _PaymentOption(
          value: 'card',
          selected: selected,
          icon: Icons.credit_card_outlined,
          label: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, Amex',
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        _PaymentOption(
          value: 'paypal',
          selected: selected,
          icon: Icons.account_balance_wallet_outlined,
          label: 'PayPal',
          subtitle: 'Pay via PayPal account',
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        _PaymentOption(
          value: 'cod',
          selected: selected,
          icon: Icons.money_outlined,
          label: 'Cash on Delivery',
          subtitle: 'Pay when you receive',
          onChanged: onChanged,
        ),
        if (selected == 'card') ...[
          const SizedBox(height: 24),
          Text('Card Details',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          TextFormField(
            controller: cardNumCtrl,
            decoration: const InputDecoration(
              hintText: '0000 0000 0000 0000',
              prefixIcon: Icon(Icons.credit_card, size: 18),
              labelText: 'Card Number',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryCtrl,
                  decoration: const InputDecoration(
                    hintText: 'MM / YY',
                    labelText: 'Expiry',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: cvvCtrl,
                  decoration: const InputDecoration(
                    hintText: '•••',
                    labelText: 'CVV',
                  ),
                  obscureText: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value, selected, label, subtitle;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _PaymentOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dark : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.dark : AppColors.lightGrey,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: isSelected ? AppColors.background : AppColors.dark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              isSelected ? AppColors.background : AppColors.dark,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.background.withValues(alpha: 0.7)
                              : AppColors.mediumGrey,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.background, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Order review ──────────────────────────────────────────────────────────────
class _OrderReview extends StatelessWidget {
  final CartProvider cart;
  final double shipping;
  final String fullName, address, city, phone, paymentMethod, cardNumber;

  const _OrderReview({
    required this.cart,
    required this.shipping,
    required this.fullName,
    required this.address,
    required this.city,
    required this.phone,
    required this.paymentMethod,
    required this.cardNumber,
  });

  @override
  Widget build(BuildContext context) {
    final items = cart.items.values.toList();
    final total = cart.finalTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Final Review',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),

        // ── Shipping summary ───────────────────────────────────────────
        _ReviewSection(
          title: 'Shipping Details',
          icon: Icons.local_shipping_outlined,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fullName, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(phone, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('$address, $city', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Payment summary ────────────────────────────────────────────
        _ReviewSection(
          title: 'Payment Method',
          icon: Icons.payments_outlined,
          content: Row(
            children: [
              Icon(
                paymentMethod == 'card'
                    ? Icons.credit_card
                    : paymentMethod == 'paypal'
                        ? Icons.account_balance_wallet
                        : Icons.money,
                size: 16,
                color: AppColors.mediumGrey,
              ),
              const SizedBox(width: 8),
              Text(
                paymentMethod == 'card'
                    ? 'Card Ending in ${cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : '****'}'
                    : paymentMethod == 'paypal'
                        ? 'PayPal'
                        : 'Cash on Delivery',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text('Order Summary',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.product.name}${item.selectedSize != null ? ' (${item.selectedSize})' : ''}  ×${item.quantity}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
            Text('Rs. ${cart.totalPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        if (cart.discountAmount > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Discount (${(cart.couponDiscountPercentage * 100).toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent)),
              Text('- Rs. ${cart.discountAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipping', style: Theme.of(context).textTheme.bodyMedium),
            Text('Rs. ${shipping.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontSize: 16)),
              Text(
                'Rs. ${total.toStringAsFixed(0)}',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontSize: 18, color: AppColors.dark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared review component ──────────────────────────────────────────────────
class _ReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;

  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.mediumGrey),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      color: AppColors.mediumGrey,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}