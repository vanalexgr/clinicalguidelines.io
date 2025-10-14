import '../core/services/optimized_storage_service.dart';
import 'locked_config.dart';

Future<void> preseedLockedServer(OptimizedStorageService storage) async {
  if (LockedConfig.allowCustomServer) {
    return;
  }

  final existingConfigs = await storage.getServerConfigs();
  final existingLocked = existingConfigs.firstWhere(
    (config) =>
        config.id == LockedConfig.serverId ||
        config.url.trim().toLowerCase() ==
            LockedConfig.baseUrl.trim().toLowerCase(),
    orElse: () => LockedConfig.buildServerConfig(),
  );

  final server = LockedConfig.buildServerConfig(existingLocked);

  await storage.saveServerConfigs([server]);
  await storage.setActiveServerId(server.id);
}
