import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/entities.dart';
import '../models/dtos.dart';

class SyncRepository {
  final SupabaseClient supabaseClient;
  final SharedPreferences sharedPreferences;

  SyncRepository({
    required this.supabaseClient,
    required this.sharedPreferences,
  });

  // ====== INBOX ======
  Future<List<InboxMessage>> getInboxMessages(String userId, {DateTime? after}) async {
    try {
      var query = supabaseClient.from('inbox_messages').select().eq('user_id', userId);
      if (after != null) {
        query = query.gt('created_at', after.toIso8601String());
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => InboxMessageDTO.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      print('Failed to sync inbox messages: $e');
      return [];
    }
  }

  Future<void> markInboxMessageRead(String messageId) async {
    try {
      await supabaseClient.from('inbox_messages').update({'is_read': true}).eq('id', messageId);
    } catch (_) {}
  }

  // ====== ORDERS ======
  Future<List<Order>> getOrders(String userId, {DateTime? after}) async {
    try {
      // For orders we only pull basic info or full if needed.
      var query = supabaseClient.from('orders').select('*, order_items(*)').eq('user_id', userId);
      if (after != null) {
        query = query.gt('updated_at', after.toIso8601String());
      }
      final response = await query.order('updated_at', ascending: false);
      return (response as List)
          .map((json) => OrderDTO.fromJson(json).toEntity(items: [])) // Items mapped separately if needed
          .toList();
    } catch (e) {
      print('Failed to sync orders: $e');
      return [];
    }
  }

  // ====== REVIEWS ======
  Future<List<Review>> getReviews(String userId, {DateTime? after}) async {
    try {
      var query = supabaseClient.from('reviews').select().eq('user_id', userId);
      if (after != null) {
        query = query.gt('updated_at', after.toIso8601String());
      }
      final response = await query.order('updated_at', ascending: false);
      return (response as List)
          .map((json) => ReviewDTO.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      print('Failed to sync reviews: $e');
      return [];
    }
  }

  Future<void> saveReview(int productId, String userId, int rating, String comment) async {
    try {
      await supabaseClient.from('reviews').insert({
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      print('Failed to save review remotely: $e');
      rethrow;
    }
  }

  Future<void> updateReview(int reviewId, int rating, String comment) async {
    try {
      await supabaseClient.from('reviews').update({
        'rating': rating,
        'comment': comment,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
    } catch (e) {
      print('Failed to update review remotely: $e');
      rethrow;
    }
  }

  Future<void> deleteReview(int reviewId) async {
     try {
       await supabaseClient.from('reviews').delete().eq('id', reviewId);
     } catch (_) {}
  }

  // ====== PROFILE ======
  Future<UserProfile?> getProfile(String userId, {DateTime? after}) async {
    try {
      var query = supabaseClient.from('profiles').select().eq('id', userId);
      if (after != null) {
        query = query.gt('updated_at', after.toIso8601String());
      }
      final response = await query.maybeSingle();
      if (response == null) return null;
      return UserProfileDTO.fromJson(response).toEntity();
    } catch (e) {
      print('Failed to sync profile: $e');
      return null;
    }
  }

  // ====== LOCAL CACHE ======
  
  // Generic key storage
  void _saveLocal(String key, List<dynamic> jsonList) {
    sharedPreferences.setString(key, jsonEncode(jsonList));
  }
  
  List<dynamic>? _loadLocal(String key) {
    final data = sharedPreferences.getString(key);
    if (data == null) return null;
    try {
       return jsonDecode(data) as List<dynamic>;
    } catch (_) {
       return null;
    }
  }

  // Inbox Cache
  void cacheInboxMessages(List<InboxMessage> messages) {
    final jsonList = messages.map((m) => {
      'id': m.id, 'user_id': m.userId, 'title': m.title, 'body': m.body,
      'category': m.category, 'is_read': m.isRead, 'created_at': m.createdAt.toIso8601String()
    }).toList();
    _saveLocal('sync_inbox', jsonList);
  }

  List<InboxMessage>? getCachedInboxMessages() {
    final list = _loadLocal('sync_inbox');
    if (list == null) return null;
    return list.map((json) => InboxMessageDTO.fromJson(json).toEntity()).toList();
  }

  // Orders Cache
  void cacheOrders(List<Order> orders) {
    final jsonList = orders.map((o) => {
      'id': o.id, 'user_id': o.userId, 'total_price': o.totalPrice,
      'status': o.status, 'created_at': o.createdAt.toIso8601String(),
      'updated_at': o.updatedAt.toIso8601String(),
    }).toList();
    _saveLocal('sync_orders', jsonList);
  }

  List<Order>? getCachedOrders() {
    final list = _loadLocal('sync_orders');
    if (list == null) return null;
    return list.map((json) => OrderDTO.fromJson(json).toEntity(items: [])).toList();
  }

  // Reviews Cache
  void cacheReviews(List<Review> reviews) {
    final jsonList = reviews.map((r) => {
      'id': r.id, 'product_id': r.productId, 'user_id': r.userId,
      'rating': r.rating, 'comment': r.comment, 'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String()
    }).toList();
    _saveLocal('sync_reviews', jsonList);
  }
  
  List<Review>? getCachedReviews() {
    final list = _loadLocal('sync_reviews');
    if (list == null) return null;
    return list.map((json) => ReviewDTO.fromJson(json).toEntity()).toList();
  }

  // Timestamp tracking
  void saveLastSyncTime(String module, DateTime time) {
    sharedPreferences.setString('sync_time_$module', time.toIso8601String());
  }

  DateTime? getLastSyncTime(String module) {
    final str = sharedPreferences.getString('sync_time_$module');
    if (str != null) {
      return DateTime.tryParse(str);
    }
    return null;
  }
}
