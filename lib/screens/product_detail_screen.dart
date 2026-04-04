import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../models/review.dart' as legacy_review;
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import '../domain/entities/entities.dart' as domain;
import '../utils/model_adapter.dart';
import '../utils/currency.dart';
import '../utils/theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _localProduct;
  late PageController _pageController;
  int _currentImageIndex = 0;
  int _quantity = 1;

  // Dynamic attribute selection
  final Map<String, String> _selectedAttributes = {};
  ProductVariant? _currentVariant;

  final Map<String, Color> _colorMap = {
    'Desert Titanium': const Color(0xFFD4A574),
    'Natural Titanium': const Color(0xFF8B8680),
    'White Titanium': const Color(0xFFF5F5F0),
    'Black Titanium': const Color(0xFF2D2D2D),
    'Black': Colors.black,
    'Orange': const Color(0xFFFF6B35),
    'White': Colors.white,
    'Silver': const Color(0xFFC0C0C0),
    'Space Gray': const Color(0xFF4A4A4A),
    'Titanium Gray': const Color(0xFF71717A),
    'Titanium Black': const Color(0xFF18181B),
    'Titanium Violet': const Color(0xFF8B5CF6),
    'Titanium Yellow': const Color(0xFFFACC15),
    'Midnight Blue': const Color(0xFF1E3A5F),
    'Blue': Colors.blue,
    'Yellow': Colors.yellow,
    'Gold': const Color(0xFFFFD700),
    'Rose Gold': const Color(0xFFB76E79),
    'Purple': Colors.purple,
    'Green': Colors.green,
    'Red': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _localProduct = widget.product;
    _pageController = PageController(initialPage: 0);

    // Initialize selection from first variant if available
    _initializeDefaultSelection();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestDetails();
    });
  }

  void _initializeDefaultSelection() {
    if (_localProduct.variants.isNotEmpty) {
      final firstVariant = _localProduct.variants.first;
      _selectedAttributes.addAll(firstVariant.attributes);
      _currentVariant = firstVariant;
    }
  }

  Future<void> _fetchLatestDetails() async {
    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final productId = int.tryParse(_localProduct.id);
      if (productId != null) {
        final domain.Product? freshProductEntity =
            await productProvider.getProductById(productId);
        if (freshProductEntity != null && mounted) {
          setState(() {
            _localProduct = freshProductEntity.toModel(
              categoryName: productProvider.getCategoryName(freshProductEntity.categoryId)
            );
            _updateVariantSelection();
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ ProductDetailScreen: Background sync failed: $e');
    }
  }

  void _updateVariantSelection() {
    // Attempt to find a variant that matches current selection
    final match = _localProduct.findVariant(_selectedAttributes);

    if (match != null) {
      _currentVariant = match;
    } else if (_localProduct.variants.isNotEmpty) {
      // If current selection is invalid for new product data, reset to first available
      _initializeDefaultSelection();
    }
  }

  void _onAttributeSelected(String attributeName, String value) {
    setState(() {
      _selectedAttributes[attributeName] = value;
      _updateVariantSelection();
    });
  }

  void _handleAddToCart(CartProvider cartProvider, AuthProvider authProvider) {
    if (!authProvider.isLoggedIn) {
      _showLoginRequiredDialog('add to cart');
      return;
    }

    cartProvider.addToCart(
      _localProduct,
      _selectedAttributes,
      variantId: _currentVariant?.id,
      quantity: _quantity,
    );
    _showAddedToCartSnackbar();
  }

  void _handleToggleWishlist(
      WishlistProvider wishlistProvider, AuthProvider authProvider) {
    if (!authProvider.isLoggedIn) {
      _showLoginRequiredDialog('add to wishlist');
      return;
    }
    wishlistProvider.toggleWishlist(_localProduct);
  }

  void _showLoginRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content:
            Text('Please login to $action and save your items across devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login Now'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isInWishlist = wishlistProvider.isInWishlist(_localProduct.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isInWishlist, wishlistProvider, authProvider),
              SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildProductImages(),
                        _buildMainInfoArea(),
                        _buildDynamicOptionsSection(),
                        _buildKeyFeaturesDetailed(),
                        _buildSpecsSection(),
                        _buildReviewsSection(),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
          _buildBottomActionBar(cartProvider, authProvider),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isInWishlist,
      WishlistProvider wishlistProvider, AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: _buildRoundButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        _buildRoundButton(
          icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
          iconColor: isInWishlist ? AppTheme.accentRed : AppTheme.textPrimary,
          onTap: () => _handleToggleWishlist(wishlistProvider, authProvider),
        ),
        const SizedBox(width: 12),
        _buildRoundButton(
          icon: Icons.share_outlined,
          onTap: () {},
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildProductImages() {
    final List<String> images = [];

    // Add current variant image override if available
    if (_currentVariant?.imageUrl != null) {
      images.add(_currentVariant!.imageUrl!);
    }

    // Add gallery images
    if (_localProduct.galleryImages.isEmpty) {
      if (images.isEmpty) images.add(_localProduct.imageUrl);
    } else {
      images.addAll(_localProduct.galleryImages);
    }

    // Remove duplicates
    final uniqueImages = images.toSet().toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemCount: uniqueImages.length,
              itemBuilder: (context, index) {
                final imageWidget = Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CachedNetworkImage(
                      imageUrl: uniqueImages[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => _buildImageShimmer(),
                      errorWidget: (context, url, error) => _buildImageError(),
                    ),
                  ),
                );

                if (index == 0) {
                  return Hero(
                    tag: 'product_${_localProduct.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: imageWidget,
                    ),
                  );
                }
                return imageWidget;
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildDotsIndicator(uniqueImages.length),
          const SizedBox(height: 20),
          _buildThumbnailStrip(uniqueImages),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator(int count) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = _currentImageIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isSelected ? 20 : 6,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderMedium,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildThumbnailStrip(List<String> images) {
    if (images.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final isSelected = _currentImageIndex == index;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.12 : 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainInfoArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _localProduct.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildRatingBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _localProduct.name,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _localProduct.description,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary.withOpacity(0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
          const SizedBox(width: 4),
          Text(
            '${_localProduct.rating}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicOptionsSection() {
    final attributes = _localProduct.availableAttributes;
    if (attributes.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: attributes.map((attr) {
          final values = _localProduct.getAttributeValues(attr);
          final title = 'Choose ${attr[0].toUpperCase()}${attr.substring(1)}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptionHeader(title),
                const SizedBox(height: 12),
                if (attr.toLowerCase() == 'color')
                  _buildDynamicColorList(values)
                else
                  _buildDynamicValueWrap(attr, values),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildDynamicColorList(List<String> values) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: values.length,
        itemBuilder: (context, index) {
          final colorName = values[index];
          final isSelected = _selectedAttributes['color'] == colorName;
          return GestureDetector(
            onTap: () => _onAttributeSelected('color', colorName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.textPrimary : AppTheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.textPrimary : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colorMap[colorName] ?? Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    colorName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicValueWrap(String attributeName, List<String> values) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: values.map((value) {
        final isSelected = _selectedAttributes[attributeName] == value;
        return GestureDetector(
          onTap: () => _onAttributeSelected(attributeName, value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyFeaturesDetailed() {
    if (_localProduct.features.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded,
                  color: AppTheme.accentOrange, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Key Highlights',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._localProduct.features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: const Icon(Icons.check_circle_outline,
                        color: AppTheme.accentGreen, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSpecsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Brand', _localProduct.brand),
          const Divider(height: 24, color: AppTheme.borderLight),
          _buildSpecRow('Category', _localProduct.category),
          const Divider(height: 24, color: AppTheme.borderLight),
          _buildSpecRow('Condition', 'Brand New'),
          const Divider(height: 24, color: AppTheme.borderLight),
          _buildStockAvailability(),
        ],
      ),
    );
  }

  Widget _buildStockAvailability() {
    // If we have variants, use variant stock. Otherwise use base product stock.
    final stock = _currentVariant?.stock ?? _localProduct.stock;
    final isProductActive = _localProduct.isActive;
    final isOutOfStock = stock <= 0 || !isProductActive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Availability',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        Text(
          isOutOfStock ? 'Restocking Soon' : 'In Stock (${stock} left)',
          style: TextStyle(
            color: isOutOfStock ? AppTheme.accentOrange : AppTheme.accentGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews (${_localProduct.reviewCount})',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_localProduct.reviews.isEmpty)
            _buildEmptyReviewsState()
          else
            Column(
              children: _localProduct.reviews
                  .take(2)
                  .map((r) => _buildReviewCard(r))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviewsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 30, color: AppTheme.textMuted),
          SizedBox(height: 8),
          Text('No feedback yet',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(legacy_review.Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryLight,
                child: Text(review.userName[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(review.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          Icons.star_rounded,
                          color: i < review.rating
                              ? AppTheme.accentOrange
                              : AppTheme.borderMedium,
                          size: 14,
                        )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment,
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
      CartProvider cartProvider, AuthProvider authProvider) {
    final double currentPrice = _currentVariant?.price ?? _localProduct.price;
    final bool isOutOfStock =
        (_currentVariant?.stock ?? _localProduct.stock) <= 0 ||
            !_localProduct.isActive;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: const Border(
                  top: BorderSide(color: AppTheme.borderLight, width: 0.5)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text(
                      formatKsh(currentPrice * _quantity),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _handleAddToCart(cartProvider, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isOutOfStock
                                ? Icons.notification_add_outlined
                                : Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                            isOutOfStock
                                ? 'Notify & Add to Cart'
                                : 'Add to Cart',
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddedToCartSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity ${_localProduct.name} to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      ),
    );
  }

  Widget _buildImageShimmer() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }

  Widget _buildImageError() {
    return const Icon(Icons.image_not_supported_outlined,
        color: AppTheme.textMuted, size: 40);
  }
}
