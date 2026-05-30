import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/widgets/common_app_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/order_model.dart';
import '../../core/services/database_service.dart';
import 'package:intl/intl.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<OrderModel> _userOrders = [];
  int _reviewCount = 0;

  Uint8List? _localImageBytes;
  bool _isUploadingPhoto = false;

  Future<void> _pickImage(UserProvider userProv) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: AppColors.dark),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.dark),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 50,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _localImageBytes = bytes;
          _isUploadingPhoto = true;
        });

        // Use a timestamp to avoid naming issues
        final safeName = '${DateTime.now().millisecondsSinceEpoch}_profile.jpg';
        await userProv.uploadProfilePhoto(bytes, safeName);
        
        if (mounted) {
          setState(() { _isUploadingPhoto = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() { 
          _isUploadingPhoto = false; 
          _localImageBytes = null; // Revert the UI if upload fails
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: ${e.toString().split(']').last}')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final db = DatabaseService();
    
    // Fetch orders and review count in parallel
    final results = await Future.wait([
      db.getUserOrders(user.uid),
      db.getUserReviewsCount(user.uid),
    ]);

    if (mounted) {
      setState(() {
        _userOrders = results[0] as List<OrderModel>;
        _reviewCount = results[1] as int;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'My Profile',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showEditDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: AppColors.dark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [

            // ── Avatar + name ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              color: AppColors.background,
              child: Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final email = userProvider.user?.email ?? 'guest@example.com';
                  return Column(
                    children: [
                      // Avatar circle with change option
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(userProvider),
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.dark,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: _localImageBytes != null
                                    ? Image.memory(
                                        _localImageBytes!,
                                        fit: BoxFit.cover,
                                        width: 88,
                                        height: 88,
                                      )
                                    : userProvider.photoUrl != null && userProvider.photoUrl!.isNotEmpty
                                        ? userProvider.photoUrl!.startsWith('http')
                                            ? CachedNetworkImage(
                                                imageUrl: userProvider.photoUrl!,
                                                fit: BoxFit.cover,
                                                width: 88,
                                                height: 88,
                                                placeholder: (context, url) => const Center(
                                                  child: SizedBox(
                                                    width: 24, height: 24,
                                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                  )
                                                ),
                                                errorWidget: (context, url, error) {
                                                  return Center(
                                                    child: Text(
                                                      userProvider.displayName.isNotEmpty 
                                                        ? userProvider.displayName.substring(0, 1).toUpperCase() 
                                                        : 'U',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Image.memory(
                                                base64Decode(userProvider.photoUrl!.split(',').last),
                                                fit: BoxFit.cover,
                                                width: 88,
                                                height: 88,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Text(
                                                    userProvider.displayName.isNotEmpty 
                                                      ? userProvider.displayName.substring(0, 1).toUpperCase() 
                                                      : 'U',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 28,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                ),
                                              )
                                        : Center(
                                            child: Text(
                                              userProvider.displayName.isNotEmpty 
                                                ? userProvider.displayName.substring(0, 1).toUpperCase() 
                                                : 'U',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                              ),
                            ),
                          ),
                          if (_isUploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _pickImage(userProvider),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        userProvider.displayName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Stats row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _StatItem(value: _userOrders.length.toString(), label: 'Orders'),
                    _Divider(),
                    Consumer<WishlistProvider>(
                      builder: (context, wishlist, _) => _StatItem(
                        value: wishlist.count.toString(),
                        label: 'Wishlist',
                      ),
                    ),
                    _Divider(),
                    _StatItem(value: _reviewCount.toString(), label: 'Reviews'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Account section ────────────────────────────────────────────
            const _SectionHeader('Account'),
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Personal Information',
              onTap: () => _showEditDialog(context),
            ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              label: 'Delivery Addresses',
              onTap: () => _showDeliveryAddresses(context),
            ),
            _MenuItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Order History',
              onTap: () => _showOrderHistory(context),
            ),
            _MenuItem(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              onTap: () => _showWishlist(context),
            ),

            const SizedBox(height: 8),

            // ── Preferences section ────────────────────────────────────────
            const _SectionHeader('Preferences'),
            Consumer<UserProvider>(
              builder: (context, userProv, _) {
                final data = userProv.userData ?? {};
                return Column(
                  children: [
                    _MenuToggle(
                      icon: Icons.notifications_outlined,
                      label: 'Push Notifications',
                      value: data['notificationsOn'] ?? true,
                      onChanged: (v) => userProv.updateProfile(notificationsOn: v),
                    ),
                    _MenuToggle(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      value: context.watch<ThemeProvider>().isDarkMode,
                      onChanged: (v) => context.read<ThemeProvider>().toggleTheme(v),
                    ),
                    _MenuItem(
                      icon: Icons.language_outlined,
                      label: 'Language',
                      trailing: data['language'] ?? 'English',
                      onTap: () => _showLanguageDialog(context, userProv),
                    ),
                    _MenuItem(
                      icon: Icons.straighten_outlined,
                      label: 'Size Preference',
                      trailing: data['sizePreference'] ?? 'M',
                      onTap: () => _showSizePreferenceDialog(context, userProv),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            // ── Support section ────────────────────────────────────────────
            const _SectionHeader('Support'),
            _MenuItem(
              icon: Icons.help_outline,
              label: 'Help & FAQ',
              onTap: () => _showHelpFaq(context),
            ),
            _MenuItem(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _showPrivacyPolicy(context),
            ),
            _MenuItem(
              icon: Icons.info_outline,
              label: 'About',
              trailing: 'v1.0.0',
              onTap: () => _showAboutDialog(context),
            ),

            const SizedBox(height: 24),

            // ── Logout button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: Icon(Icons.logout, size: 18,
                      color: AppColors.error),
                  label: Text(
                    'Log Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
    );
  }

  // ── Edit profile dialog ────────────────────────────────────────────────────
  void _showEditDialog(BuildContext context) {
    final userProv = context.read<UserProvider>();
    final data = userProv.userData ?? {};
    
    final nameCtrl  = TextEditingController(text: userProv.displayName);
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Edit Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            const Text('Full Name',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Your name',
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text('Phone',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+94 77 000 0000',
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await userProv.updateProfile(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Order history bottom sheet ─────────────────────────────────────────────
  void _showOrderHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isLoading = true;
        List<OrderModel> orders = [];

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            // Fetch orders once when sheet opens
            if (isLoading && orders.isEmpty) {
              final user = context.read<UserProvider>().user;
              if (user != null) {
                DatabaseService().getUserOrders(user.uid).then((fetchedOrders) {
                  if (context.mounted) {
                    setStateSheet(() {
                      orders = fetchedOrders;
                      isLoading = false;
                    });
                  }
                });
              } else {
                isLoading = false;
              }
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text('Order History',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator())),
                  if (!isLoading && orders.isEmpty)
                    const Expanded(child: Center(child: Text('No orders found'))),
                  if (!isLoading && orders.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final order = orders[i];
                          final status = order.status;
                          final statusColor = status == 'Delivered'
                              ? AppColors.success
                              : status == 'Shipped'
                                  ? AppColors.accent
                                  : AppColors.mediumGrey;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.shopping_bag_outlined,
                                      size: 20, color: AppColors.dark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                                          style: Theme.of(context)
                                              .textTheme.labelLarge),
                                      const SizedBox(height: 2),
                                      Text(DateFormat('dd MMM yyyy').format(order.date),
                                          style: Theme.of(context)
                                              .textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Rs. ${order.totalAmount.toStringAsFixed(0)}',
                                        style: Theme.of(context)
                                            .textTheme.labelLarge),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Logout confirm ─────────────────────────────────────────────────────────
  void _showDeliveryAddresses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer<AddressProvider>(
        builder: (context, addressProvider, _) {
          final addresses = addressProvider.addresses;
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Delivery Addresses',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Expanded(
                    child: addresses.isEmpty
                        ? const Center(child: Text('No addresses saved'))
                        : ListView.builder(
                            itemCount: addresses.length,
                            itemBuilder: (context, index) {
                              final address = addresses[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  tileColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  title: Text(address.label),
                                  subtitle: Text('${address.street}, ${address.city}'),
                                  leading: Icon(Icons.location_on_outlined,
                                      color: AppColors.dark),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                    onPressed: () => addressProvider.removeAddress(address.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showAddAddressDialog(context),
                      child: const Text('Add New Address'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: const InputDecoration(hintText: 'Label (e.g. Home)')),
            const SizedBox(height: 8),
            TextField(controller: streetCtrl, decoration: const InputDecoration(hintText: 'Street')),
            const SizedBox(height: 8),
            TextField(controller: cityCtrl, decoration: const InputDecoration(hintText: 'City')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (labelCtrl.text.isNotEmpty && streetCtrl.text.isNotEmpty) {
                context.read<AddressProvider>().addAddress(Address(
                  id: DateTime.now().toString(),
                  label: labelCtrl.text,
                  street: streetCtrl.text,
                  city: cityCtrl.text,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showWishlist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer<WishlistProvider>(
        builder: (context, wishlist, _) {
          final items = wishlist.items;
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text('My Wishlist',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                if (items.isEmpty)
                  const Expanded(child: Center(child: Text('Your wishlist is empty'))),
                if (items.isNotEmpty)
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final product = items[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  width: 60, height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: Theme.of(context).textTheme.labelLarge),
                                    const SizedBox(height: 4),
                                    Text('Rs. ${product.price.toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.accent,
                                            )),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                                onPressed: () {
                                  context.read<CartProvider>().addItem(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added ${product.name} to cart'), duration: const Duration(seconds: 3)),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.favorite, size: 20, color: AppColors.heartActive),
                                onPressed: () => wishlist.toggleWishlist(product),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, UserProvider userProv) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select Language'),
        children: ['English', 'Spanish', 'French'].map((lang) {
          return SimpleDialogOption(
            onPressed: () {
              userProv.updateProfile(language: lang);
              Navigator.pop(context);
            },
            child: Text(lang),
          );
        }).toList(),
      ),
    );
  }

  void _showSizePreferenceDialog(BuildContext context, UserProvider userProv) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose Size Preference'),
        children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
          return SimpleDialogOption(
            onPressed: () {
              userProv.updateProfile(sizePreference: size);
              Navigator.pop(context);
            },
            child: Text(size),
          );
        }).toList(),
      ),
    );
  }

  void _showHelpFaq(BuildContext context) {
    final faqItems = [
      {
        'question': 'How do I track my order?',
        'answer': 'Go to Order History and tap the most recent order to see the status.',
      },
      {
        'question': 'Can I change my delivery address?',
        'answer': 'Yes, use Delivery Addresses to review saved locations and add a new one.',
      },
      {
        'question': 'How do returns work?',
        'answer': 'Contact support within 7 days of delivery to start a return request.',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Help & FAQ',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...faqItems.map((faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Text(faq['question']!),
                    subtitle: Text(faq['answer']!),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We collect only the information needed to complete orders and improve your shopping experience. We never share your personal details with third parties without your consent.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Fashion House',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Fashion House. All rights reserved.',
      children: [
        const SizedBox(height: 12),
        const Text('Fashion House helps you browse and shop the latest trends in style.'),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture references before async gap
              final router = GoRouter.of(context);
              final cart = context.read<CartProvider>();
              final wishlist = context.read<WishlistProvider>();
              final userProv = context.read<UserProvider>();

              // Clear local providers for a fresh session
              cart.clearCart();
              wishlist.clearWishlist();

              Navigator.pop(dialogContext);

              // Sign out from Firebase
              await userProv.signOut();

              // Navigate to login
              router.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 36, color: AppColors.lightGrey);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: AppColors.mediumGrey,
            ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.dark),
      ),
      title: Text(label,
          style: Theme.of(context).textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!,
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 18, color: AppColors.mediumGrey),
        ],
      ),
    );
  }
}

class _MenuToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MenuToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.dark),
      ),
      title: Text(label,
          style: Theme.of(context).textTheme.bodyLarge),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.dark,
      ),
    );
  }
}