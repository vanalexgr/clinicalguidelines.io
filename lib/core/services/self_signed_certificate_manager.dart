import '../models/server_config.dart';
import 'self_signed_certificate_manager_io.dart'
    if (dart.library.html) 'self_signed_certificate_manager_stub.dart'
    as platform;

/// Coordinates opt-in trust for self-signed TLS certificates.
///
/// On IO platforms we install an [HttpOverrides] that whitelists the servers
/// flagged in [ServerConfig.allowSelfSignedCertificates]. On web platforms the
/// helpers are no-ops because browsers manage TLS validation themselves.
class SelfSignedCertificateManager {
  const SelfSignedCertificateManager._();

  static const SelfSignedCertificateManager instance =
      SelfSignedCertificateManager._();

  void ensureInitialized() => platform.ensureInitialized();

  void updateTrustedServers(Iterable<ServerConfig> configs) =>
      platform.updateTrustedServers(configs);

  void clearTrustedServers() => platform.clearTrustedServers();
}
