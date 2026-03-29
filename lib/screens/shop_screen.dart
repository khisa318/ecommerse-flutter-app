import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/model_adapter.dart';
import '../utils/product_card.dart';
import '../utils/product_grid_loader.dart';
import '../utils/search_bar.dart';
import '../utils/theme.dart';
import '../domain/entities/entities.dart' as entities;

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Sync search controller if query exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (provider.searchQuery != null) {
        _searchController.text = provider.searchQuery!;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.7) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (!provider.isLoading &&
          provider.hasMoreProducts &&
          (provider.searchQuery == null || provider.searchQuery!.isEmpty)) {
        provider.loadMoreProducts();
      }
    }
  }

  List<Map<String, dynamic>> _convertCategories(List categories) {
    final categoryMap = {
      'Smartphones': Icons.smartphone,
      'Audio': Icons.headset,
      'Accessories': Icons.cable,
      'Gaming Accessories': Icons.sports_esports,
      'Storage Accessories': Icons.sd_storage,
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
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final allProducts = productProvider.products;
        final searchResults = productProvider.searchResults;
        final isSearching = productProvider.isSearching || (productProvider.searchQuery != null && productProvider.searchQuery!.isNotEmpty);
        final isSelectingCategory = productProvider.selectedCategoryId != null;
        
        // Hybrid Logic:
        // 1. If searching, show search results
        // 2. If selecting category AND backend is loading, show a local filter of currently loaded products
        // 3. Otherwise, show allProducts (which are either main discoveries or server-side filtered category list)
        late List<entities.Product> displayProducts;
        
        if (isSearching) {
          displayProducts = searchResults;
        } else if (isSelectingCategory && productProvider.isLoading) {
          // Perform local filter on the memory list until backend returns for instant feedback
          final selectedIds = productProvider.getDescendantIds(productProvider.selectedCategoryId!);
          displayProducts = allProducts.where((p) => selectedIds.contains(p.categoryId)).toList();
        } else {
          displayProducts = allProducts;
        }

        final displayCategories = _convertCategories(productProvider.categories);
        final isLoadingInitially = productProvider.isInitialDataLoading && allProducts.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await productProvider.refreshProducts();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Improved Shop Banner
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF1E293B),
                            Color(0xFF334155),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discover',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Premium Tech',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Explore our curated collection of high-performance gadgets and smart lifestyle essentials.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Search & Categories Section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SearchBarWidget(
                        searchController: _searchController,
                        selectedCategory: productProvider.selectedCategoryId == null 
                            ? 'All' 
                            : displayCategories.firstWhere(
                                (c) => c['id'] == productProvider.selectedCategoryId,
                                orElse: () => {'name': 'All'}
                              )['name'],
                        onCategoryChanged: (categoryName) {
                          if (categoryName == 'All' || categoryName == null) {
                            productProvider.setCategoryFilter(null);
                          } else {
                            final cat = displayCategories.firstWhere(
                              (c) => c['name'] == categoryName,
                              orElse: () => {'id': null}
                            );
                            if (cat['id'] != null) {
                              productProvider.setCategoryFilter(cat['id']);
                              _searchController.clear();
                            }
                          }
                        },
                        categories: displayCategories,
                        onSearchChanged: (val) {
                          productProvider.searchProducts(val);
                        },
                      ),
                    ),
                  ),

                  // Section Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Text(
                        isSearching 
                            ? 'Search Results' 
                            : productProvider.selectedCategoryId != null 
                                ? 'Category Results'
                                : 'All Products',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  if (productProvider.isSearching)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: AppTheme.primaryColor,
                          backgroundColor: AppTheme.borderLight,
                        ),
                      ),
                    ),

                  if (isLoadingInitially)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(child: ProductGridLoader(itemCount: 6)),
                    )
                  else if (displayProducts.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try adjusting your search or category',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ProductCard(
                            product: displayProducts[index].toModel(),
                          ),
                          childCount: displayProducts.length,
                        ),
                      ),
                    ),

                  if (productProvider.isLoading && !isLoadingInitially)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
