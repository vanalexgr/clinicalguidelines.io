import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/services/api_service.dart';
import 'package:conduit/core/utils/user_avatar_utils.dart';
import 'package:conduit/core/utils/model_icon_utils.dart';
import 'package:conduit/core/models/server_config.dart';

// Manual Mock ApiService (no generation needed)
class FakeApiService implements ApiService {
  @override
  final ServerConfig serverConfig;

  FakeApiService(this.serverConfig);

  @override
  String get baseUrl => serverConfig.url;
  
  // Implement other required members as no-op or throw UnimplementedError
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('URL Upgrade Tests', () {
    late FakeApiService httpsApi;
    late FakeApiService httpApi;

    setUp(() {
      httpsApi = FakeApiService(
        ServerConfig(
          id: '1',
          name: 'Secure Server',
          url: 'https://secure.example.com',
        ),
      );

      httpApi = FakeApiService(
        ServerConfig(
          id: '2',
          name: 'Insecure Server',
          url: 'http://insecure.example.com',
        ),
      );
    });

    test('resolveUserProfileImageUrl upgrades HTTP to HTTPS when API is HTTPS', () {
      const insecureUrl = 'http://example.com/image.jpg';
      final result = resolveUserProfileImageUrl(httpsApi, insecureUrl);
      expect(result, 'https://example.com/image.jpg');
    });

    test('resolveUserProfileImageUrl keeps HTTP when API is HTTP', () {
      const insecureUrl = 'http://example.com/image.jpg';
      final result = resolveUserProfileImageUrl(httpApi, insecureUrl);
      expect(result, 'http://example.com/image.jpg');
    });

    test('resolveUserProfileImageUrl handles relative URLs correctly', () {
      const relativeUrl = '/images/avatar.png';
      // Should use baseUrl which is https://secure.example.com
      final result = resolveUserProfileImageUrl(httpsApi, relativeUrl);
      expect(result, 'https://secure.example.com/images/avatar.png');
    });

    test('resolveModelIconUrl upgrades HTTP to HTTPS when API is HTTPS', () {
      const insecureUrl = 'http://example.com/icon.png';
      final result = resolveModelIconUrl(httpsApi, insecureUrl);
      expect(result, 'https://example.com/icon.png');
    });

    test('resolveModelIconUrl keeps HTTPS as is', () {
      const secureUrl = 'https://example.com/icon.png';
      // Should remain untouched
      final result = resolveModelIconUrl(httpsApi, secureUrl);
      expect(result, 'https://example.com/icon.png');
    });
  });
}
