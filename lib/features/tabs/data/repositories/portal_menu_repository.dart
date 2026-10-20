import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/auth/data/services/uth_portal_service.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_model.dart';

abstract class PortalMenuRepository {
  Future<List<PortalMenuItem>> getSideMenu(String token);
  Future<List<PortalMenuItem>> getMainMenu(String token);
}

class PortalMenuRepositoryImpl implements PortalMenuRepository {
  final UthPortalService _portalService;

  PortalMenuRepositoryImpl({required this._portalService});

  @override
  Future<List<PortalMenuItem>> getSideMenu(String token) async {
    if (token.isEmpty) return [];
    return _portalService.getSideMenu(token);
  }

  @override
  Future<List<PortalMenuItem>> getMainMenu(String token) async {
    if (token.isEmpty) return [];
    return _portalService.getMainMenu(token);
  }
}

final portalMenuRepositoryProvider = Provider<PortalMenuRepository>((ref) {
  final portalService = ref.watch(uthPortalServiceProvider);
  return PortalMenuRepositoryImpl(portalService: portalService);
});
