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
          .select(
              'id, product_id, variant_id, quantity, selected_attributes, products(*)')
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

        final variantId = cartRow['variant_id']?.toString();
        final selectedAttributes =
            Map<String, String>.from(cartRow['selected_attributes'] ?? {});

        loadedItems.add(
          CartItem(
            id: cartRow['id'].toString(),
            product: product,
            variantId: variantId,
            quantity: (cartRow['quantity'] as num?)?.toInt() ?? 1,
            selectedAttributes: selectedAttributes,
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

  Future<void> addToCart(
      Product product, Map<String, String> selectedAttributes,
      {String? variantId, int quantity = 1}) async {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.variantId == variantId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          id: DateTime.now()
              .millisecondsSinceEpoch
              .toString(), // Temp ID until sync
          product: product,
          variantId: variantId,
          quantity: quantity,
          selectedAttributes: selectedAttributes,
        ),
      );
    }

    _notifySafely();

    // In a real app we would sync with backend here
    final productId = int.parse(product.id);
    await _syncAddToCart(productId, variantId, selectedAttributes);
  }

  Future<void> _syncAddToCart(int productId, String? variantId,
      Map<String, String> selectedAttributes) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _supabase.from('cart_items').upsert({
        'user_id': userId,
        'product_id': productId,
        'variant_id': variantId != null ? int.tryParse(variantId) : null,
        'selected_attributes': selectedAttributes,
        'quantity': _items
            .firstWhere((i) =>
                i.product.id == productId.toString() &&
                i.variantId == variantId)
            .quantity,
      });
    } catch (e) {
      debugPrint('Error syncing add to cart: $e');
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    final itemIndex = _items.indexWhere((item) => item.id == cartItemId);
    if (itemIndex < 0) return;

    _items.removeAt(itemIndex);
    _notifySafely();

    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('id', int.parse(cartItemId));
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      await loadCart();
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) return;

    _items[index].quantity = quantity;
    _notifySafely();

    // Sync with backend
    try {
      await _supabase
          .from('cart_items')
          .update({'quantity': quantity}).eq('id', int.parse(cartItemId));
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  Future<void> incrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) return;
    await updateQuantity(cartItemId, _items[index].quantity + 1);
  }

  Future<void> decrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) return;
    await updateQuantity(cartItemId, _items[index].quantity - 1);
  }

  Future<void> clearCart() async {
    final userId = _currentUserId;
    _items.clear();
    _notifySafely();

    if (userId == null) return;

    try {
      await _supabase.from('cart_items').delete().eq('user_id', userId);
    } catch (e) {
      _errorMessage = 'Failed to clear cart: ${e.toString()}';
      _notifySafely();
    }
  }

  bool isInCart(String productId, {String? variantId}) {
    return _items.any(
        (item) => item.product.id == productId && item.variantId == variantId);
  }

  Future<Product> _buildCartProduct(Map<String, dynamic> productJson) async {
    final productId = productJson['id'].toString();
    String imageUrl = 'lib/images/smartphones/mobile2.jpg';

    try {
      final images =
          await remoteDataSource.getProductImages(int.parse(productId));
      if (images.isNotEmpty) imageUrl = images.first;
    } catch (_) {}

    final title = productJson['title']?.toString() ?? 'Product';
    final priceValue = (productJson['price'] as num?)?.toDouble() ?? 0;
    final currentPrice = priceValue / 100.0;

    // We build a minimal product with potential variants if available in JSON
    final variants = (productJson['variants'] as List<dynamic>?)?.map((v) {
          final variantJson = Map<String, dynamic>.from(v);
          return ProductVariant(
            id: variantJson['id'].toString(),
            price: (variantJson['price'] as num?) != null ? (variantJson['price'] as num).toDouble() / 100.0 : null,
            stock: (variantJson['stock_quantity'] as num?)?.toInt() ?? 0,
            imageUrl: variantJson['image_url']?.toString(),
            attributes: Map<String, String>.from(variantJson['attributes'] ?? {}),
          );
        }).toList() ?? [];

    return Product(
      id: productId,
      name: title,
      brand: (productJson['brand'] ?? 'Generic').toString(),
      description: (productJson['description'] ?? '').toString(),
      price: currentPrice,
      imageUrl: imageUrl,
      galleryImages: [imageUrl],
      rating: 4.5,
      reviewCount: 0,
      variants: variants,
      features: [],
      category: (productJson['category'] ?? 'Electronics').toString(),
      stock: (productJson['stock_quantity'] as num?)?.toInt() ?? 0,
      isActive: productJson['is_active'] ?? true,
    );
  }

  void _notifySafely() {
    if (_isDisposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
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
