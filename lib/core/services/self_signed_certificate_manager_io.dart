import 'dart:io';

import '../models/server_config.dart';

final _IoSelfSignedCertificateManager _manager =
    _IoSelfSignedCertificateManager();

void ensureInitialized() => _manager.ensureInitialized();

void updateTrustedServers(Iterable<ServerConfig> configs) =>
    _manager.updateTrustedServers(configs);

void clearTrustedServers() => _manager.clearTrustedServers();

class _IoSelfSignedCertificateManager {
  _IoSelfSignedCertificateManager();

  _ConduitHttpOverrides? _overrides;

  void ensureInitialized() {
    if (_overrides != null) return;

    final overrides = _ConduitHttpOverrides();
    HttpOverrides.global = overrides;
    _overrides = overrides;
  }

  void updateTrustedServers(Iterable<ServerConfig> configs) {
    ensureInitialized();
    _overrides?.updateTrustedServers(configs);
  }

  void clearTrustedServers() {
    _overrides?.clearTrustedServers();
  }
}

class _ConduitHttpOverrides extends HttpOverrides {
  final Set<_TrustedEndpoint> _trustedEndpoints = {};

  void updateTrustedServers(Iterable<ServerConfig> configs) {
    _trustedEndpoints
      ..clear()
      ..addAll(
        configs
            .where((config) => config.allowSelfSignedCertificates)
            .map((config) => _TrustedEndpoint.fromUrl(config.url))
            .whereType<_TrustedEndpoint>(),
      );
  }

  void clearTrustedServers() {
    _trustedEndpoints.clear();
  }

  bool _shouldTrust(String host, int port) {
    for (final endpoint in _trustedEndpoints) {
      if (endpoint.matches(host, port)) {
        return true;
      }
    }
    return false;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            _shouldTrust(host, port);
    return client;
  }
}

class _TrustedEndpoint {
  const _TrustedEndpoint({required this.host, this.port});

  final String host;
  final int? port;

  static _TrustedEndpoint? fromUrl(String url) {
    final uri = _normalizeUrl(url);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    final normalizedHost = uri.host.toLowerCase();
    final normalizedPort = uri.hasPort ? uri.port : null;
    return _TrustedEndpoint(host: normalizedHost, port: normalizedPort);
  }

  static Uri? _normalizeUrl(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    Uri? parsed = Uri.tryParse(value.trim());
    if (parsed == null) {
      return null;
    }
    if (!parsed.hasScheme) {
      parsed =
          Uri.tryParse('https://${value.trim()}') ??
          Uri.tryParse('http://${value.trim()}');
    }
    return parsed;
  }

  bool matches(String otherHost, int otherPort) {
    final normalizedHost = otherHost.toLowerCase();
    if (normalizedHost != host) {
      return false;
    }
    if (port == null) {
      return true;
    }
    return port == otherPort;
  }
}
