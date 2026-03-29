import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../domain/entities/entities.dart';
import '../data/repositories/sync_repository.dart';

class SyncProvider with ChangeNotifier {
  final SyncRepository syncRepository;
  final String? userId;

  List<InboxMessage> _inboxMessages = [];
  List<Order> _orders = [];
  List<Review> _reviews = [];
  UserProfile? _profile;

  bool _isSyncingInbox = false;
  bool _isSyncingOrders = false;
  bool _isSyncingReviews = false;
  bool _isSyncingProfile = false;

  DateTime? _lastInboxSync;
  DateTime? _lastOrdersSync;
  DateTime? _lastReviewsSync;
  DateTime? _lastProfileSync;

  bool _isDisposed = false;

  SyncProvider({
    required this.syncRepository,
    required this.userId,
  }) {
    if (userId != null) {
      _loadFromCache();
      SchedulerBinding.instance.addPostFrameCallback((_) {
         syncAll();
      });
    }
  }

  // Getters
  List<InboxMessage> get inboxMessages => _inboxMessages;
  List<Order> get orders => _orders;
  List<Review> get reviews => _reviews;
  UserProfile? get profile => _profile;

  bool get isSyncingInbox => _isSyncingInbox;
  bool get isSyncingOrders => _isSyncingOrders;
  bool get isSyncingReviews => _isSyncingReviews;
  bool get isSyncingProfile => _isSyncingProfile;

  DateTime? get lastInboxSync => _lastInboxSync;
  DateTime? get lastOrdersSync => _lastOrdersSync;
  DateTime? get lastReviewsSync => _lastReviewsSync;

  void _loadFromCache() {
    _inboxMessages = syncRepository.getCachedInboxMessages() ?? [];
    _orders = syncRepository.getCachedOrders() ?? [];
    _reviews = syncRepository.getCachedReviews() ?? [];
    // Profile is usually handled by AuthProvider, but we can cache it here too if needed
    
    _lastInboxSync = syncRepository.getLastSyncTime('inbox');
    _lastOrdersSync = syncRepository.getLastSyncTime('orders');
    _lastReviewsSync = syncRepository.getLastSyncTime('reviews');
    _lastProfileSync = syncRepository.getLastSyncTime('profile');
    
    notifyListeners();
  }

  Future<void> syncAll() async {
    if (userId == null) return;
    await Future.wait([
      syncInbox(),
      syncOrders(),
      syncReviews(),
      syncProfile(),
    ]);
  }

  Future<void> syncInbox({bool force = false}) async {
    if (_isSyncingInbox || userId == null) return;
    _isSyncingInbox = true;
    _notifySafely();

    final lastSync = force ? null : _lastInboxSync;
    final news = await syncRepository.getInboxMessages(userId!, after: lastSync);
    
    if (news.isNotEmpty) {
      // Merge: Add new ones, update existing by ID
      final Map<String, InboxMessage> map = {for (var m in _inboxMessages) m.id: m};
      for (var n in news) {
        map[n.id] = n;
      }
      _inboxMessages = map.values.toList();
      _inboxMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      syncRepository.cacheInboxMessages(_inboxMessages);
    }

    _lastInboxSync = DateTime.now();
    syncRepository.saveLastSyncTime('inbox', _lastInboxSync!);
    _isSyncingInbox = false;
    _notifySafely();
  }

  Future<void> syncOrders({bool force = false}) async {
    if (_isSyncingOrders || userId == null) return;
    _isSyncingOrders = true;
    _notifySafely();

    final lastSync = force ? null : _lastOrdersSync;
    final news = await syncRepository.getOrders(userId!, after: lastSync);
    
    if (news.isNotEmpty) {
      final Map<int, Order> map = {for (var o in _orders) o.id: o};
      for (var n in news) {
        map[n.id] = n;
      }
      _orders = map.values.toList();
      _orders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      syncRepository.cacheOrders(_orders);
    }

    _lastOrdersSync = DateTime.now();
    syncRepository.saveLastSyncTime('orders', _lastOrdersSync!);
    _isSyncingOrders = false;
    _notifySafely();
  }

  Future<void> syncReviews({bool force = false}) async {
    if (_isSyncingReviews || userId == null) return;
    _isSyncingReviews = true;
    _notifySafely();

    final lastSync = force ? null : _lastReviewsSync;
    final news = await syncRepository.getReviews(userId!, after: lastSync);
    
    if (news.isNotEmpty) {
      final Map<int, Review> map = {for (var r in _reviews) r.id: r};
      for (var n in news) {
        map[n.id] = n;
      }
      _reviews = map.values.toList();
      _reviews.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      syncRepository.cacheReviews(_reviews);
    }

    _lastReviewsSync = DateTime.now();
    syncRepository.saveLastSyncTime('reviews', _lastReviewsSync!);
    _isSyncingReviews = false;
    _notifySafely();
  }

  Future<void> syncProfile({bool force = false}) async {
    if (_isSyncingProfile || userId == null) return;
    _isSyncingProfile = true;
    _notifySafely();

    final lastSync = force ? null : _lastProfileSync;
    final updated = await syncRepository.getProfile(userId!, after: lastSync);
    
    if (updated != null) {
      _profile = updated;
      // Ideally AuthProvider should be notified or it should listen
    }

    _lastProfileSync = DateTime.now();
    syncRepository.saveLastSyncTime('profile', _lastProfileSync!);
    _isSyncingProfile = false;
    _notifySafely();
  }

  // Optimistic Review
  Future<void> addReview(int productId, int rating, String comment) async {
    if (userId == null) return;
    
    // Remote
    await syncRepository.saveReview(productId, userId!, rating, comment);
    
    // Refresh
    await syncReviews(force: true);
  }

  Future<void> updateReview(int reviewId, int rating, String comment) async {
    await syncRepository.updateReview(reviewId, rating, comment);
    await syncReviews(force: true);
  }

  Future<void> deleteReview(int reviewId) async {
     await syncRepository.deleteReview(reviewId);
     _reviews.removeWhere((r) => r.id == reviewId);
     syncRepository.cacheReviews(_reviews);
     notifyListeners();
  }

  Future<void> markInboxRead(String messageId) async {
    await syncRepository.markInboxMessageRead(messageId);
    final index = _inboxMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final m = _inboxMessages[index];
      _inboxMessages[index] = InboxMessage(
        id: m.id, userId: m.userId, title: m.title, body: m.body,
        category: m.category, isRead: true, createdAt: m.createdAt
      );
      syncRepository.cacheInboxMessages(_inboxMessages);
      notifyListeners();
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
