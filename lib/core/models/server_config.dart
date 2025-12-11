import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'backend_config.dart';

part 'server_config.freezed.dart';
part 'server_config.g.dart';

/// Container for passing server and backend config during authentication flow.
@immutable
class AuthFlowConfig {
  const AuthFlowConfig({required this.serverConfig, this.backendConfig});

  /// The server configuration (URL, headers, etc.).
  final ServerConfig serverConfig;

  /// The backend configuration (auth methods, features, etc.).
  /// May be null if not yet fetched.
  final BackendConfig? backendConfig;
}

@freezed
sealed class ServerConfig with _$ServerConfig {
  const factory ServerConfig({
    required String id,
    required String name,
    required String url,
    String? apiKey,
    @Default({}) Map<String, String> customHeaders,
    DateTime? lastConnected,
    @Default(false) bool isActive,

    /// Whether to trust self-signed TLS certificates for this server.
    @Default(false) bool allowSelfSignedCertificates,
  }) = _ServerConfig;

  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);
}
