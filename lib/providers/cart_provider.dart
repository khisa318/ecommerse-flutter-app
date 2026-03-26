import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/datasources/remote_datasource.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final RemoteDataSource remoteDataSource;
  final SupabaseClient _supabase;

  CartProvider({
    required this.remoteDataSource,
    SupabaseClient? supabaseClient,
  }) : _supabase = supabaseClient ?? Supabase.instance.client {
    _currentUserId = _supabase.auth.currentUser?.id;
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      unawaited(_handleAuthChange(data.session?.user.id));
    });
    if (_currentUserId != null) {
      unawaited(loadCart());
    }
  }

  final List<CartItem> _items = [];
  StreamSubscription<AuthState>? _authSubscription;
  String? _currentUserId;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get shippingCost => _items.isEmpty ? 0 : 15.0;
  double get tax => subtotal * 0.08;
  double get total => subtotal + shippingCost + tax;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _handleAuthChange(String? userId) async {
    if (_currentUserId == userId) {
      return;
    }

    _currentUserId = userId;
    _errorMessage = null;

    if (userId == null) {
      _items.clear();
      _notifySafely();
      return;
    }

    await loadCart();
  }

  Future<void> loadCart() async {
    final userId = _currentUserId;
    if (userId == null) {
      _items.clear();
      _notifySafely();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final cartRows = await _supabase
          .from('cart_items')
          .select('product_id, quantity, products(*)')
          .eq('user_id', userId);

      final loadedItems = <CartItem>[];
      for (final row in cartRows as List) {
        final cartRow = Map<String, dynamic>.from(row as Map);
        final productJson = cartRow['products'];
        if (productJson is! Map) {
          continue;
        }

        final product = await _buildCartProduct(
          Map<String, dynamic>.from(productJson),
        );

        loadedItems.add(
          CartItem(
            id: product.id,
            product: product,
            quantity: (cartRow['quantity'] as num?)?.toInt() ?? 1,
            selectedColor:
                product.colors.isNotEmpty ? product.colors.first : 'Default',
            selectedStorage: product.storageOptions.isNotEmpty
                ? product.storageOptions.first
                : 'Standard',
          ),
        );
      }

      _items
        ..clear()
        ..addAll(loadedItems);
    } catch (e) {
      _errorMessage = 'Failed to load cart: ${e.toString()}';
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> addToCart(Product product, String color, String storage) async {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
      _items[existingIndex].selectedColor = color;
      _items[existingIndex].selectedStorage = storage;
    } else {
      _items.add(
        CartItem(
          id: product.id,
          product: product,
          selectedColor: color,
          selectedStorage: storage,
        ),
      );
    }

    _notifySafely();
    await _persistProductQuantity(product.id, _quantityForProduct(product.id));
  }

  Future<void> removeFromCart(String cartItemId) async {
    final itemIndex = _items.indexWhere((item) => item.id == cartItemId);
    if (itemIndex < 0) {
      return;
    }

    final productId = _items[itemIndex].product.id;
    _items.removeAt(itemIndex);
    _notifySafely();
    await _deleteProductFromRemote(productId);
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) {
      return;
    }

    _items[index].quantity = quantity;
    _notifySafely();
    await _persistProductQuantity(_items[index].product.id, quantity);
  }

  Future<void> incrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) {
      return;
    }

    _items[index].quantity++;
    _notifySafely();
    await _persistProductQuantity(
      _items[index].product.id,
      _items[index].quantity,
    );
  }

  Future<void> decrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) {
      return;
    }

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
      _notifySafely();
      await _persistProductQuantity(
        _items[index].product.id,
        _items[index].quantity,
      );
      return;
    }

    await removeFromCart(cartItemId);
  }

  Future<void> clearCart() async {
    final userId = _currentUserId;
    _items.clear();
    _notifySafely();

    if (userId == null) {
      return;
    }

    try {
      await _supabase.from('cart_items').delete().eq('user_id', userId);
    } catch (e) {
      _errorMessage = 'Failed to clear cart: ${e.toString()}';
      _notifySafely();
    }
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int _quantityForProduct(String productId) {
    final item = _items.firstWhere((entry) => entry.product.id == productId);
    return item.quantity;
  }

  Future<void> _persistProductQuantity(String productId, int quantity) async {
    final userId = _currentUserId;
    if (userId == null) {
      _errorMessage = 'Please login to save cart changes';
      _notifySafely();
      return;
    }

    try {
      await _supabase.from('cart_items').upsert({
        'user_id': userId,
        'product_id': int.parse(productId),
        'quantity': quantity,
      });
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to sync cart: ${e.toString()}';
      await loadCart();
    } finally {
      _notifySafely();
    }
  }

  Future<void> _deleteProductFromRemote(String productId) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', int.parse(productId));
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to remove item from cart: ${e.toString()}';
      await loadCart();
    } finally {
      _notifySafely();
    }
  }

  Future<Product> _buildCartProduct(Map<String, dynamic> productJson) async {
    final productId = productJson['id'].toString();
    String imageUrl = 'lib/images/smartphones/mobile2.jpg';

    try {
      final images = await remoteDataSource.getProductImages(
        int.parse(productId),
      );
      if (images.isNotEmpty) {
        imageUrl = images.first;
      }
    } catch (_) {
      // Keep fallback image.
    }

    final title =
        (productJson['title'] ?? productJson['name'] ?? 'Product').toString();
    final description = (productJson['description'] ?? '').toString();
    final priceValue = (productJson['price'] as num?)?.toDouble() ?? 0;
    final discountPercentage =
        (productJson['discount_percentage'] as num?)?.toDouble() ?? 0;
    final currentPrice = priceValue / 100.0;
    final originalPrice = discountPercentage > 0
        ? currentPrice / (1 - (discountPercentage / 100))
        : null;

    return Product(
      id: productId,
      name: title,
      brand: (productJson['brand'] ?? 'Generic Brand').toString(),
      description: description,
      price: currentPrice,
      originalPrice: originalPrice,
      imageUrl: imageUrl,
      galleryImages: [imageUrl],
      rating: 4.5,
      reviewCount: 0,
      reviews: const [],
      colors: const ['Black', 'White'],
      storageOptions: const ['128GB', '256GB'],
      features: [description],
      category: (productJson['category'] ?? 'Electronics').toString(),
      isOnSale: discountPercentage > 0,
    );
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
    _authSubscription?.cancel();
    super.dispose();
  }
}
