import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/tabs/data/repositories/portal_menu_repository.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_model.dart';

export 'package:uth_flow/features/tabs/data/repositories/portal_menu_repository.dart'
    show portalMenuRepositoryProvider;

final portalSideMenuProvider =
    FutureProvider.autoDispose<List<PortalMenuItem>>((ref) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final repository = ref.watch(portalMenuRepositoryProvider);
  return repository.getSideMenu(token);
});

final portalMainMenuProvider =
    FutureProvider.autoDispose<List<PortalMenuItem>>((ref) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final repository = ref.watch(portalMenuRepositoryProvider);
  return repository.getMainMenu(token);
});
