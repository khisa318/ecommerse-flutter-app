import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/cyberspex_branding.dart';
import '../utils/model_adapter.dart';
import '../utils/product_card.dart';
import '../utils/product_grid_loader.dart';
import '../utils/search_bar.dart';
import '../utils/theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _searchQuery;

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
      'Speakers': Icons.speaker,
    };

    return [
      {'name': 'All', 'icon': Icons.grid_view, 'color': AppTheme.categoryMore},
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
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final allProducts = productProvider.products;
        final filteredProducts =
            _searchQuery != null && _searchQuery!.isNotEmpty
                ? productProvider.searchResults
                : allProducts;
        final displayCategories =
            _convertCategories(productProvider.categories);
        final isLoadingProducts = productProvider.isInitialDataLoading &&
            allProducts.isEmpty &&
            (_searchQuery == null || _searchQuery!.isEmpty);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F2E67),
                          AppTheme.primaryColor,
                          Color(0xFF0EA5E9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CyberspexWordmark(
                          titleColor: Colors.white,
                          subtitleColor: Color(0xFFD7E8FF),
                          compact: true,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Shop premium gadgets, accessories, and smart essentials curated for your lifestyle.',
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _HeroMetric(
                                label: 'Live Products',
                                value: '${allProducts.length}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HeroMetric(
                                label: 'Search Results',
                                value: '${filteredProducts.length}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SearchBarWidget(
                      searchController: _searchController,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                          if (_selectedCategory == 'All') {
                            _selectedCategory = null;
                          }
                        });
                      },
                      categories: displayCategories,
                      onSearchChanged: _onSearchChanged,
                    ),
                  ),
                ),
                if (productProvider.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unable to load products',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productProvider.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => productProvider.getProducts(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Featured In Shop',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Text(
                            '${filteredProducts.length} items',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (productProvider.isSearching)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryColor,
                        backgroundColor: AppTheme.borderLight,
                      ),
                    ),
                  ),
                if (isLoadingProducts)
                  const SliverToBoxAdapter(
                    child: ProductGridLoader(itemCount: 6),
                  )
                else if (productProvider.isLoading && filteredProducts.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (filteredProducts.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            productProvider.hasLoadedInitialData
                                ? 'No products found'
                                : 'Loading products...',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: filteredProducts[index].toModel(),
                        ),
                        childCount: filteredProducts.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (query.isNotEmpty) {
      Provider.of<ProductProvider>(context, listen: false)
          .searchProducts(query);
    } else {
      Provider.of<ProductProvider>(context, listen: false).clearSearch();
    }
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
