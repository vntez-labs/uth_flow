import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/notification/data/notification_repository.dart';
import 'package:uth_flow/features/notification/domain/notification_model.dart';

/// Provider danh sách thông báo của sinh viên từ Portal UTH
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final token = ref.watch(authTokenProvider) ?? '';
  if (token.isEmpty) return [];

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications(token);
});

/// Số lượng thông báo (length của body từ API getNote)
final notificationCountProvider = Provider.autoDispose<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.asData?.value.length ?? 0;
});
