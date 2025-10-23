import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:conduit/core/providers/app_providers.dart';
import 'package:conduit/features/auth/providers/unified_auth_providers.dart';

/// Builds HTTP headers for protected image requests.
///
/// Includes Authorization (Bearer token or API key) and any server-configured
/// custom headers. Returns `null` if no headers are needed.
Map<String, String>? buildImageHeadersFromRef(Ref ref) {
  final api = ref.read(apiServiceProvider);
  final token = ref.read(authTokenProvider3);
  return _build(api, token);
}

Map<String, String>? buildImageHeadersFromWidgetRef(WidgetRef ref) {
  final api = ref.read(apiServiceProvider);
  final token = ref.read(authTokenProvider3);
  return _build(api, token);
}

/// Same as [buildImageHeadersFromRef] but using a [ProviderContainer], useful
/// when you don't have a `Ref` (e.g., in non-Consumer widgets/utilities).
Map<String, String>? buildImageHeadersFromContainer(
  ProviderContainer container,
) {
  final api = container.read(apiServiceProvider);
  final token = container.read(authTokenProvider3);
  return _build(api, token);
}

Map<String, String>? _build(dynamic api, String? token) {
  final headers = <String, String>{};

  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  } else if (api?.serverConfig.apiKey != null &&
      api!.serverConfig.apiKey!.isNotEmpty) {
    headers['Authorization'] = 'Bearer ${api.serverConfig.apiKey}';
  }

  if (api != null && api.serverConfig.customHeaders.isNotEmpty) {
    headers.addAll(api.serverConfig.customHeaders);
  }

  return headers.isEmpty ? null : headers;
}
