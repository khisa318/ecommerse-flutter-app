import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/remote_datasource.dart';
import '../models/product.dart';
import '../utils/model_adapter.dart';

class WishlistProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  final RemoteDataSource _remoteDataSource;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isDisposed = false;

  WishlistProvider({
    SupabaseClient? supabaseClient,
    required RemoteDataSource remoteDataSource,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _remoteDataSource = remoteDataSource {
    _userId = _supabase.auth.currentUser?.id;
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      unawaited(_handleAuthChange(data.session?.user.id));
    });
  }

  List<Product> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;

  List<Product> get wishlistItems => List.unmodifiable(_wishlistItems);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _wishlistItems.length;

  Future<void> syncUser(String? userId) async {
    if (_userId == userId) {
      return;
    }

    _userId = userId;
    _errorMessage = null;

    if (_userId == null) {
      _wishlistItems = [];
      _notifySafely();
      return;
    }

    await loadWishlist();
  }

  Future<void> _handleAuthChange(String? userId) async {
    await syncUser(userId);
  }

  String? _getCurrentUserId() {
    return _supabase.auth.currentUser?.id ?? _userId;
  }

  Future<void> loadWishlist() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      _wishlistItems = [];
      _notifySafely();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final response = await _supabase
          .from('wishlist')
          .select('product_id')
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      final productIds = (response as List)
          .map((item) => item['product_id'].toString())
          .toList();

      _wishlistItems = await Future.wait(
        productIds.map(_fetchWishlistProduct),
      );
    } catch (e) {
      _errorMessage = 'Failed to load wishlist: ${e.toString()}';
      debugPrint('Error loading wishlist: $e');
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<Product> _fetchWishlistProduct(String productId) async {
    final dto = await _remoteDataSource.getProductById(int.parse(productId));
    String imageUrl = 'lib/images/smartphones/mobile2.jpg';

    try {
      final images = await _remoteDataSource.getProductImages(dto.id);
      if (images.isNotEmpty) {
        imageUrl = images.first;
      }
    } catch (_) {
      // Keep fallback image when no product image is available.
    }

    final entity = dto.toEntity(
      imageUrl: imageUrl,
      images: [imageUrl],
    );

    return entity.toModel();
  }

  Future<bool> addToWishlist(Product product) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      _errorMessage = 'Please log in to add to wishlist';
      _notifySafely();
      return false;
    }

    if (isInWishlist(product.id)) {
      _errorMessage = 'Product already in wishlist';
      _notifySafely();
      return false;
    }

    try {
      await _supabase.from('wishlist').insert({
        'user_id': userId,
        'product_id': int.parse(product.id),
        'added_at': DateTime.now().toIso8601String(),
      });

      _wishlistItems = [product, ..._wishlistItems];
      _errorMessage = null;
      _notifySafely();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add to wishlist: ${e.toString()}';
      debugPrint('Error adding to wishlist: $e');
      _notifySafely();
      return false;
    }
  }

  Future<bool> removeFromWishlist(String productId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return false;
    }

    try {
      await _supabase
          .from('wishlist')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', int.parse(productId));

      _wishlistItems.removeWhere((product) => product.id == productId);
      _errorMessage = null;
      _notifySafely();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove from wishlist: ${e.toString()}';
      debugPrint('Error removing from wishlist: $e');
      _notifySafely();
      return false;
    }
  }

  bool isInWishlist(String productId) {
    return _wishlistItems.any((p) => p.id == productId);
  }

  Future<bool> clearWishlist() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return false;
    }

    try {
      await _supabase.from('wishlist').delete().eq('user_id', userId);
      _wishlistItems = [];
      _errorMessage = null;
      _notifySafely();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to clear wishlist: ${e.toString()}';
      debugPrint('Error clearing wishlist: $e');
      _notifySafely();
      return false;
    }
  }

  Future<bool> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      return removeFromWishlist(product.id);
    }
    return addToWishlist(product);
  }

  Future<bool> moveToCart(Product product) async {
    try {
      await removeFromWishlist(product.id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to move to cart: ${e.toString()}';
      debugPrint('Error moving to cart: $e');
      _notifySafely();
      return false;
    }
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
