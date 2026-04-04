import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/exceptions/exceptions.dart';
import '../data/repositories/repositories_impl.dart';
import '../domain/entities/entities.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepositoryImpl productRepository;
  final CategoryRepositoryImpl categoryRepository;

  List<Product> _products = [];
  List<Product> _flashDeals = [];
  List<Product> _categoryResults = [];
  List<Category> _categories = [];
  List<Category> _allCategories = []; // Store all categories for recursive lookup
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isInitialDataLoading = true;
  bool _hasLoadedInitialData = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _categoryPage = 1;
  final int _pageSize = 20;
  bool _hasMoreProducts = true;
  bool _hasMoreCategoryProducts = true;
  bool _isDisposed = false;

  // New state tracking for backend-side filtering
  int? _selectedCategoryId;
  String? _searchQuery;

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get categoryResults => List.unmodifiable(_categoryResults);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Category> get allCategories => List.unmodifiable(_allCategories);
  List<Product> get searchResults => List.unmodifiable(_searchResults);
  List<Product> get flashDeals => List.unmodifiable(_flashDeals);

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

  /// Get a category name by its ID
  String getCategoryName(int categoryId) {
    if (_allCategories.isEmpty) return 'Category';
    final match = _allCategories.cast<Category?>().firstWhere(
      (c) => c!.id == categoryId,
      orElse: () => null,
    );
    return match?.name ?? 'Category';
  }

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isInitialDataLoading => _isInitialDataLoading;
  bool get hasLoadedInitialData => _hasLoadedInitialData;
  String? get errorMessage => _errorMessage;
  bool get hasMoreProducts => _selectedCategoryId == null ? _hasMoreProducts : _hasMoreCategoryProducts;

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
    final isCategoryFetch = _selectedCategoryId != null;
    final pageNum = page ?? (isCategoryFetch ? _categoryPage : _currentPage);

    if (refresh) {
      if (!isCategoryFetch && _searchQuery == null) {
         _products.clear();
         productRepository.clearProductCache();
         _currentPage = 1;
         _hasMoreProducts = true;
      } else if (isCategoryFetch) {
         _categoryResults.clear();
         _categoryPage = 1;
         _hasMoreCategoryProducts = true;
      }
    }

    if (_isLoading) return; // Prevent duplicate calls

    // Load cache instantly on first page if available and empty
    if (pageNum == 1 && _products.isEmpty && !refresh && !isCategoryFetch) {
      final cached = productRepository.getCachedProductsPage(page: 1);
      if (cached != null && cached.isNotEmpty) {
        _products = _mixPhonesAndOthers(List.from(cached));
        _updateFlashDeals();
        _notifySafely();
      }
    }

    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      List<int>? categoryIds;
      if (isCategoryFetch) {
        categoryIds = getDescendantIds(_selectedCategoryId!);
      }

      final newProducts = await productRepository.getProducts(
        page: pageNum,
        limit: _pageSize,
        categoryIds: categoryIds,
      );

      if (newProducts.isEmpty) {
        if (pageNum == 1) {
          if (isCategoryFetch) _categoryResults = [];
          else _products = [];
        }
        if (isCategoryFetch) _hasMoreCategoryProducts = false;
        else _hasMoreProducts = false;
      } else {
        final random = Random();
        if (pageNum == 1) {
          if (isCategoryFetch) {
            _categoryResults = List.from(newProducts);
            _categoryResults.shuffle(random);
          } else {
            _products = _mixPhonesAndOthers(List.from(newProducts));
          }
        } else {
          final shuffledNewProducts = List.from(newProducts)..shuffle(random);
          if (isCategoryFetch) {
            final existingIds = _categoryResults.map((p) => p.id).toSet();
            for (var np in shuffledNewProducts) {
              if (!existingIds.contains(np.id)) _categoryResults.add(np);
            }
          } else {
            final existingIds = _products.map((p) => p.id).toSet();
            final mixedNew = _mixPhonesAndOthers(List.from(newProducts));
            for (var np in mixedNew) {
              if (!existingIds.contains(np.id)) _products.add(np);
            }
          }
        }
        
        if (isCategoryFetch) {
          _categoryPage = pageNum;
          _hasMoreCategoryProducts = newProducts.length >= _pageSize;
        } else {
          _currentPage = pageNum;
          _hasMoreProducts = newProducts.length >= _pageSize;
        }
      }

      _hasLoadedInitialData = true;
      _isInitialDataLoading = false;
      _isLoading = false;
      _updateFlashDeals();
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
    final isCategoryFetch = _selectedCategoryId != null;
    if (isCategoryFetch ? !_hasMoreCategoryProducts : !_hasMoreProducts) return;
    if (_isLoading) return;
    
    await getProducts(page: (isCategoryFetch ? _categoryPage : _currentPage) + 1);
  }

  void _updateFlashDeals() {
    if (_products.isEmpty) {
      _flashDeals = [];
      return;
    }
    
    // Group by categoryId
    final Map<int, List<Product>> byCategory = {};
    for (var p in _products) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }
    
    List<Product> result = [];
    final random = Random();
    
    // Pick 1 random from each category until we have 6, or repeat if needed
    List<int> catIds = byCategory.keys.toList()..shuffle(random);
    
    // First pass: 1 from each distinct category
    for (var cid in catIds) {
      if (result.length >= 6) break;
      var catProds = List<Product>.from(byCategory[cid]!);
      if (catProds.isNotEmpty) {
        catProds.shuffle(random);
        result.add(catProds.first);
      }
    }
    
    // If less than 6 (e.g. only 3 categories in DB), backfill from remaining
    if (result.length < 6) {
       List<Product> remaining = byCategory.values.expand((list) => list).where((p) => !result.contains(p)).toList();
       remaining.shuffle(random);
       for (var p in remaining) {
         if (result.length >= 6) break;
         result.add(p);
       }
    }

    _flashDeals = result;
  }

  List<Product> _mixPhonesAndOthers(List<Product> items) {
    if (items.isEmpty) return items;
    
    final random = Random();
    List<Product> phones = [];
    List<Product> others = [];
    
    for (var p in items) {
      final catName = getCategoryName(p.categoryId).toLowerCase();
      if (catName.contains('phone') || catName.contains('mobile') || catName.contains('smartphone')) {
        phones.add(p);
      } else {
        others.add(p);
      }
    }
    
    phones.shuffle(random);
    others.shuffle(random);
    
    List<Product> mixed = [];
    int pIdx = 0;
    int oIdx = 0;
    
    while (pIdx < phones.length || oIdx < others.length) {
      // Add 1 or 2 phones
      if (pIdx < phones.length) mixed.add(phones[pIdx++]);
      if (pIdx < phones.length && random.nextBool()) mixed.add(phones[pIdx++]);
      
      // Add 1 other
      if (oIdx < others.length) mixed.add(others[oIdx++]);
    }
    
    return mixed;
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

    // Trigger backend fetch for category specifically
    await refreshProducts();
  }

  Future<void> getCategories() async {
    try {
      final allCats = await categoryRepository.getCategories();
      _allCategories = List.from(allCats);
      
      _categories = _allCategories.where((cat) => cat.isActive).toList();
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
