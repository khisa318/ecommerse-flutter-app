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

  List<Product> get products => List.unmodifiable(_products);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get searchResults => List.unmodifiable(_searchResults);
  List<Product> get flashDeals => _products.take(5).toList();

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

  Future<void> getProducts({int? page}) async {
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final pageNum = page ?? _currentPage;
      final newProducts = await productRepository.getProducts(
        page: pageNum,
        limit: _pageSize,
      );

      if (newProducts.isEmpty) {
        _hasMoreProducts = false;
      } else {
        if (pageNum == 1) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }
        _currentPage = pageNum;
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

  Future<Product?> getProductById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final product = await productRepository.getProductById(id);
      _isLoading = false;
      _notifySafely();
      return product;
    } on EntityNotFoundException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      _notifySafely();
      return null;
    } catch (e) {
      _errorMessage = 'Error loading product: ${e.toString()}';
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
      _errorMessage = 'Error loading product details: ${e.toString()}';
      _isLoading = false;
      _notifySafely();
      return null;
    }
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final categoryProducts = await productRepository.getProducts(
        page: 1,
        limit: _pageSize,
        categoryId: categoryId,
      );

      _isLoading = false;
      _notifySafely();
      return categoryProducts;
    } catch (e) {
      _errorMessage = 'Error loading category products: ${e.toString()}';
      _isLoading = false;
      _notifySafely();
      return [];
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _notifySafely();
      return;
    }

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

  List<Product> getFlashDeals() {
    return flashDeals;
  }

  Future<void> getCategories() async {
    try {
      _categories = await categoryRepository.getCategories();
      _notifySafely();
    } catch (e) {
      _errorMessage = 'Error loading categories: ${e.toString()}';
      _notifySafely();
    }
  }

  Future<Category?> getCategoryById(int id) async {
    try {
      final category = await categoryRepository.getCategoryById(id);
      return category;
    } catch (_) {
      return null;
    }
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    _notifySafely();
  }

  void resetProducts() {
    _products = [];
    _currentPage = 1;
    _hasMoreProducts = true;
    _notifySafely();
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) {
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
