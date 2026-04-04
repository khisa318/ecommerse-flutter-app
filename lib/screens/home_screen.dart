import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/theme.dart';
import '../utils/bannerCarousel.dart';
import '../utils/home_app_bar.dart';
import '../utils/search_bar.dart';
import '../utils/flash_deals_header.dart';
import '../utils/product_card.dart';
import '../utils/model_adapter.dart';
import '../utils/product_grid_loader.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _convertCategories(List categories) {
    final categoryMap = {
      'Smartphones': Icons.smartphone,
      'Mobile': Icons.smartphone,
      'Headphones': Icons.headphones,
      'Headphone': Icons.headphones,
      'Tablets': Icons.tablet_mac,
      'Laptop': Icons.laptop_mac,
      'Laptops': Icons.laptop_mac,
      'Speakers': Icons.speaker,
      'Speaker': Icons.speaker,
    };

    return [
      {'name': 'All', 'icon': Icons.grid_view, 'color': AppTheme.categoryMore, 'id': null},
      ...categories.map((cat) {
        final name = cat.name ?? 'Category';
        return {
          'name': name,
          'icon': categoryMap[name] ?? Icons.category,
          'color': AppTheme.primaryColor,
          'id': cat.id,
        };
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final flashDeals = productProvider.flashDeals;
    final displayCategories = _convertCategories(productProvider.categories);
    final isLoadingFlashDeals = productProvider.isInitialDataLoading &&
        productProvider.products.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: HomeAppBar(cartProvider: cartProvider),
            ),

            // Search Bar - Simplified for Home
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                  );
                },
                child: AbsorbPointer(
                  child: SearchBarWidget(
                    searchController: _searchController,
                    selectedCategory: 'All',
                    onCategoryChanged: (categoryName) {
                      // Handled in Shop
                    },
                    categories: displayCategories,
                  ),
                ),
              ),
            ),

            // Banner Carousel
            SliverToBoxAdapter(
              child: BannerCarousel(),
            ),

            // Error Message
            if (productProvider.errorMessage != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Error Loading Products',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        productProvider.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => productProvider.getProducts(),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (productProvider.errorMessage != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.red.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          productProvider.errorMessage!.replaceAll('Exception: ', ''),
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => productProvider.getProducts(refresh: true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            // Flash Deals Section
            SliverToBoxAdapter(
              child: FlashDealsHeader(
                onSeeAllPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                  );
                },
              ),
            ),

            // Flash Deals Grid (Showing latest 6)
            if (isLoadingFlashDeals)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: ProductGridLoader()),
              )
            else if (flashDeals.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Text(
                      productProvider.hasLoadedInitialData
                          ? 'No flash deals available'
                          : 'Preparing premium gadgets...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        ProductCard(product: flashDeals[index].toModel(
                          categoryName: productProvider.getCategoryName(flashDeals[index].categoryId)
                        )),
                    childCount: flashDeals.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}
