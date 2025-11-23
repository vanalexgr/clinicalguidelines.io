import 'package:flutter/foundation.dart';

/// Subset of the backend `/api/config` response the app cares about.
@immutable
class BackendConfig {
  const BackendConfig({this.enableWebsocket});

  /// Mirrors `features.enable_websocket` from OpenWebUI.
  final bool? enableWebsocket;

  /// Returns a copy with updated fields.
  BackendConfig copyWith({bool? enableWebsocket}) {
    return BackendConfig(
      enableWebsocket: enableWebsocket ?? this.enableWebsocket,
    );
  }

  /// Whether the backend only allows WebSocket transport.
  bool get websocketOnly => enableWebsocket == true;

  /// Whether the backend only allows HTTP polling transport.
  bool get pollingOnly => enableWebsocket == false;

  /// Whether the backend permits choosing WebSocket-only mode.
  bool get supportsWebsocketOnly => !pollingOnly;

  /// Whether the backend permits choosing polling fallback.
  bool get supportsPolling => !websocketOnly;

  /// Returns the enforced transport mode derived from backend policy.
  String? get enforcedTransportMode {
    if (websocketOnly) return 'ws';
    if (pollingOnly) return 'polling';
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enable_websocket': enableWebsocket,
    };
  }

  static BackendConfig fromJson(Map<String, dynamic> json) {
    bool? enableWebsocket;
    // Try canonical format first
    final value = json['enable_websocket'];
    if (value is bool) {
      enableWebsocket = value;
    }

    // Fallback to nested format for backwards compatibility
    if (enableWebsocket == null) {
      final features = json['features'];
      if (features is Map<String, dynamic>) {
        final nestedValue = features['enable_websocket'];
        if (nestedValue is bool) {
          enableWebsocket = nestedValue;
        }
      }
    }

    return BackendConfig(enableWebsocket: enableWebsocket);
  }
}
