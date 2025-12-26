import '../models/server_config.dart';

const String kLockedServerUrl = 'https://chat.clinicalguidelines.io';

const bool kServerLockEnabled = true;

final lockedServerConfig = ServerConfig(
  id: 'clinical-guidelines-locked',
  name: 'Clinical Guidelines',
  url: 'https://chat.clinicalguidelines.io',
  isActive: true,
);
