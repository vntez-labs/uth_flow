import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/moodle/data/repositories/moodle_repository.dart';
import 'package:uth_flow/features/moodle/domain/moodle_event_model.dart';

export 'package:uth_flow/features/moodle/data/repositories/moodle_repository.dart'
    show moodleRepositoryProvider;

final moodleDeadlinesProvider =
    FutureProvider.autoDispose<List<MoodleEventModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final moodleRepo = ref.watch(moodleRepositoryProvider);
  return moodleRepo.getDeadlines(user: user);
});
