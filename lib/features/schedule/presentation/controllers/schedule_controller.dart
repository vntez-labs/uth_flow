import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/schedule/data/repositories/schedule_repository.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';

export 'package:uth_flow/features/schedule/data/repositories/schedule_repository.dart'
    show DailyScheduleData, ScheduleRepository, scheduleRepositoryProvider;

final dailyScheduleProvider =
    FutureProvider.autoDispose<DailyScheduleData>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null || token.isEmpty) {
    return const DailyScheduleData();
  }

  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  return scheduleRepo.getDailySchedule(token);
});

final todayScheduleProvider =
    FutureProvider.autoDispose<List<ScheduleModel>>((ref) async {
  final daily = await ref.watch(dailyScheduleProvider.future);
  return daily.todayClasses;
});

final scheduleForDateProvider =
    FutureProvider.family.autoDispose<List<ScheduleModel>, DateTime>((ref, date) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  return scheduleRepo.getScheduleByDate(token, date);
});

final weeklyScheduleProvider = FutureProvider.family
    .autoDispose<List<ScheduleModel>, DateTime>((ref, date) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  return scheduleRepo.getWeeklySchedule(token, date: date);
});

final monthlyScheduleProvider = FutureProvider.family
    .autoDispose<List<MonthScheduleDay>, DateTime>((ref, date) async {
  final normalizedDate = DateTime(date.year, date.month, 1);
  final token = ref.watch(authTokenProvider) ?? '';
  final scheduleRepo = ref.watch(scheduleRepositoryProvider);
  return scheduleRepo.getMonthlySchedule(token, date: normalizedDate);
});
