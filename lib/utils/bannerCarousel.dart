import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../screens/product_detail_screen.dart';
import 'model_adapter.dart';
import 'theme.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;

  Timer? _autoScrollTimer;
  Timer? _refreshTimer;
  List<Product> _carouselProducts = [];

  final List<List<Color>> _bannerGradients = [
    [const Color(0xFF4A6CF7), const Color(0xFF8B5CF6)],
    [const Color(0xFF1E293B), const Color(0xFF334155)],
    [const Color(0xFF059669), const Color(0xFF10B981)],
    [const Color(0xFFF97316), const Color(0xFFEA580C)],
    [const Color(0xFFE11D48), const Color(0xFFBE123C)],
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _startRefreshTimer();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselProducts.isNotEmpty && _pageController.hasClients) {
        int nextIndex = _currentBannerIndex + 1;
        if (nextIndex >= _carouselProducts.length) {
          nextIndex = 0;
          _pageController.animateToPage(nextIndex,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut);
        } else {
          _pageController.animateToPage(nextIndex,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut);
        }
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _selectRandomProducts();
    });
  }

  void _selectRandomProducts() {
    if (!mounted) return;
    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (provider.products.isNotEmpty) {
      final random = Random();
      final productsTemp = provider.products
          .map((p) => p.toModel(categoryName: provider.getCategoryName(p.categoryId)))
          .toList();
      productsTemp.shuffle(random);
      setState(() {
        _carouselProducts = productsTemp.take(5).toList();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_carouselProducts.isEmpty) {
      _selectRandomProducts();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes so that when products arrive from the database, we can set them.
    final provider = Provider.of<ProductProvider>(context);

    if (_carouselProducts.isEmpty && provider.products.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectRandomProducts();
      });
    }

    if (_carouselProducts.isEmpty) {
      // Show empty space or a skeleton while loading
      return const SizedBox(height: 180 + 32);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _carouselProducts.length,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final product = _carouselProducts[index];
                final gradient =
                    _bannerGradients[index % _bannerGradients.length];
                return _buildBannerCard(product, gradient);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPageIndicators(),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _carouselProducts.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentBannerIndex == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentBannerIndex == index
                ? AppTheme.primaryColor
                : AppTheme.borderMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(Product product, List<Color> gradientColors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Pattern
              Positioned(
                right: -40,
                top: -30,
                child: Container(
                  width: 220,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Product Image
              Positioned(
                right: 10,
                top: 10,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    width: 140,
                    errorWidget: (_, __, ___) => Container(
                      width: 140,
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(Icons.image, color: Colors.white54),
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: 140, // Prevent overlapping with image and overflowing
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, top: 15, bottom: 15, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW ARRIVAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Shop Now',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
