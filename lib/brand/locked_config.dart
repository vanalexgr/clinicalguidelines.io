import '../core/models/server_config.dart';

class LockedConfig {
  static const String baseUrl = String.fromEnvironment(
    'SERVER_BASE_URL',
    defaultValue: 'https://chat.clinicalguidelines.io',
  );

  static const bool allowCustomServer = bool.fromEnvironment(
    'ALLOW_CUSTOM_SERVER',
    defaultValue: false,
  );

  static const Map<String, String> defaultHeaders = <String, String>{
    // 'X-Org': 'ClinicalGuidelines',
  };

  static const String serverId = 'clinical-guidelines-server';
  static const String serverName = 'Clinical Guidelines';

  static ServerConfig buildServerConfig([ServerConfig? existing]) {
    return ServerConfig(
      id: existing?.id ?? serverId,
      name: existing?.name ?? serverName,
      url: baseUrl,
      apiKey: existing?.apiKey,
      customHeaders: Map<String, String>.from(defaultHeaders),
      lastConnected: existing?.lastConnected,
      isActive: true,
      allowSelfSignedCertificates:
          existing?.allowSelfSignedCertificates ?? false,
    );
  }
}
