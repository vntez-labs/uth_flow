import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/core/network/portal_api_client.dart';
import 'package:uth_flow/features/notification/domain/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications(
    String token, {
    bool forceRefresh = false,
  });
  void clearCache();
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 15);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final PortalApiClient portalClient;

  static final Map<String, _CacheEntry<List<NotificationModel>>> _cache = {};

  NotificationRepositoryImpl({required this.portalClient});

  @override
  void clearCache() {
    _cache.clear();
  }

  @override
  Future<List<NotificationModel>> getNotifications(
    String token, {
    bool forceRefresh = false,
  }) async {
    if (token.isEmpty) return [];

    final cacheKey = token.hashCode.toString();
    final cached = _cache[cacheKey];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    try {
      final rawList = await portalClient.getNotifications(token);
      final notifications = rawList
          .map((item) => NotificationModel.fromJson(item))
          .toList();

      _cache[cacheKey] = _CacheEntry(notifications);
      return notifications;
    } catch (_) {
      // Fallback cache nếu api gặp sự cố, hoặc trả về rỗng không để crash màn hình
      return cached?.data ?? [];
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final portalClient = ref.watch(portalApiClientProvider);
  return NotificationRepositoryImpl(portalClient: portalClient);
});
