import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/exceptions/exceptions.dart';
import '../data/repositories/repositories_impl.dart';
import '../domain/entities/entities.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepositoryImpl productRepository;
  final CategoryRepositoryImpl categoryRepository;

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Category> _allCategories = []; // Store all categories for recursive lookup
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isInitialDataLoading = true;
  bool _hasLoadedInitialData = false;
  String? _errorMessage;

  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreProducts = true;
  bool _isDisposed = false;

  // New state tracking for backend-side filtering
  int? _selectedCategoryId;
  String? _searchQuery;

  List<Product> get products => List.unmodifiable(_products);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Category> get allCategories => List.unmodifiable(_allCategories);
  List<Product> get searchResults => List.unmodifiable(_searchResults);
  List<Product> get flashDeals => _products.take(6).toList();

  int? get selectedCategoryId => _selectedCategoryId;
  String? get searchQuery => _searchQuery;

  /// Recursively get all descendant category IDs
  List<int> getDescendantIds(int parentId) {
    if (_allCategories.isEmpty) return [parentId];
    
    final ids = [parentId];
    final children = _allCategories.where((c) => c.parentId == parentId);
    for (final child in children) {
      ids.addAll(getDescendantIds(child.id));
    }
    return ids;
  }

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isInitialDataLoading => _isInitialDataLoading;
  bool get hasLoadedInitialData => _hasLoadedInitialData;
  String? get errorMessage => _errorMessage;
  bool get hasMoreProducts => _hasMoreProducts;

  ProductProvider({
    required this.productRepository,
    required this.categoryRepository,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || _hasLoadedInitialData) {
        return;
      }
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    _isInitialDataLoading = true;
    _notifySafely();

    try {
      await getCategories();
      await getProducts();
    } finally {
      _isInitialDataLoading = false;
      _hasLoadedInitialData = true;
      _notifySafely();
    }
  }

  Future<void> refreshProducts() async {
    // Refresh for search or category or all
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      await searchProducts(_searchQuery!);
    } else {
      await getProducts(page: 1, refresh: true);
    }
  }

  Future<void> getProducts({int? page, bool refresh = false}) async {
    final pageNum = page ?? _currentPage;

    if (refresh) {
      // Logic for hybrid filtering: 
      // We don't clear immediately if we're just switching categories to allow local filtering while fetching
      if (_selectedCategoryId == null && _searchQuery == null) {
         _products.clear();
      }
      _currentPage = 1;
      _hasMoreProducts = true;
      productRepository.clearProductCache();
    }

    if (_isLoading) return; // Prevent duplicate calls

    // Load cache instantly on first page if available and empty
    if (pageNum == 1 && _products.isEmpty && !refresh && _selectedCategoryId == null) {
      final cached = productRepository.getCachedProductsPage(page: 1);
      if (cached != null && cached.isNotEmpty) {
        _products = List.from(cached);
        _products.shuffle(); // Randomize on initial load from cache
        _notifySafely();
      }
    }

    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      List<int>? categoryIds;
      if (_selectedCategoryId != null) {
        categoryIds = getDescendantIds(_selectedCategoryId!);
      }

      final newProducts = await productRepository.getProducts(
        page: pageNum,
        limit: _pageSize,
        categoryIds: categoryIds,
      );

      if (newProducts.isEmpty) {
        if (pageNum == 1) _products = [];
        _hasMoreProducts = false;
      } else {
        if (pageNum == 1) {
          _products = List.from(newProducts);
          // Only shuffle if it's the main discoveries page
          if (_selectedCategoryId == null) {
            _products.shuffle();
          }
        } else {
          // Append preventing duplicates
          final existingIds = _products.map((p) => p.id).toSet();
          for (var np in newProducts) {
            if (!existingIds.contains(np.id)) {
              _products.add(np);
            }
          }
        }
        _currentPage = pageNum;
        _hasMoreProducts = newProducts.length >= _pageSize;
      }

      _isLoading = false;
      _notifySafely();
    } on NetworkException catch (e) {
      _errorMessage = 'Network error: ${e.message}';
      _isLoading = false;
      _notifySafely();
    } catch (e) {
      _errorMessage = 'Failed to load products: ${e.toString()}';
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMoreProducts || _isLoading) {
      return;
    }
    await getProducts(page: _currentPage + 1);
  }

  // --- Search Functions ---
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _notifySafely();
      return;
    }

    // Clear category filter when searching as they are mutually exclusive
    _selectedCategoryId = null;

    _isSearching = true;
    _errorMessage = null;
    _notifySafely();

    try {
      _searchResults = await productRepository.searchProducts(query);
      _isSearching = false;
      _notifySafely();
    } on NetworkException catch (e) {
      _errorMessage = 'Search failed: ${e.message}';
      _isSearching = false;
      _notifySafely();
    } catch (e) {
      _errorMessage = 'Search error: ${e.toString()}';
      _isSearching = false;
      _notifySafely();
    }
  }

  void clearSearch() {
    _searchQuery = null;
    _searchResults = [];
    _isSearching = false;
    _notifySafely();
    refreshProducts();
  }

  // --- Category Selection ---
  Future<void> setCategoryFilter(int? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    
    _selectedCategoryId = categoryId;
    
    // Clear search when category is selected
    _searchQuery = null;
    _searchResults = [];
    _isSearching = false;

    // Trigger backend fetch
    // Note: We don't clear _products here. 
    // The UI will perform local filtering on current _products while loading new ones.
    await refreshProducts();
  }

  Future<void> getCategories() async {
    try {
      final allCats = await categoryRepository.getCategories();
      _allCategories = List.from(allCats);
      
      const majorCategoryNames = [
        'Smartphones', 
        'Audio', 
        'Accessories', 
        'Gaming Accessories', 
        'Storage Accessories'
      ];

      final filtered = <Category>[];
      for (var name in majorCategoryNames) {
        final found = _allCategories.firstWhere(
          (cat) => cat.name.toLowerCase() == name.toLowerCase() && cat.isActive,
          orElse: () => Category(id: -1, name: '', isActive: false, createdAt: DateTime.now())
        );
        if (found.id != -1) {
          filtered.add(found);
        }
      }
      _categories = filtered;
      _notifySafely();
    } catch (e) {
      _errorMessage = 'Error loading categories: ${e.toString()}';
      _notifySafely();
    }
  }

  Future<Product?> getProductById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();
    try {
      final product = await productRepository.getProductById(id);
      _isLoading = false;
      _notifySafely();
      return product;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _notifySafely();
      return null;
    }
  }

  Future<(Product, List<Review>)?> getProductWithReviews(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();
    try {
      final result = await productRepository.getProductWithReviews(productId);
      _isLoading = false;
      _notifySafely();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _notifySafely();
      return null;
    }
  }

  void _notifySafely() {
    if (_isDisposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
