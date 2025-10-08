import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_providers.dart';

part 'connectivity_service.g.dart';

enum ConnectivityStatus { online, offline, checking }

class ConnectivityService {
  ConnectivityService(this._dio, this._ref, [Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity() {
    _startConnectivityMonitoring();
  }

  final Dio _dio;
  final Ref _ref;
  final Connectivity _connectivity;

  final _connectivityController =
      StreamController<ConnectivityStatus>.broadcast();

  Timer? _initialCheckTimer;
  Timer? _pollTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Completer<void>? _activeCheck;
  List<ConnectivityResult>? _lastConnectivityResults;

  ConnectivityStatus _lastStatus = ConnectivityStatus.checking;
  Duration _interval = const Duration(seconds: 10);
  int _recentFailures = 0;
  int _lastLatencyMs = -1;
  bool _hasNetwork = true;
  bool _queuedImmediateCheck = false;

  Stream<ConnectivityStatus> get connectivityStream =>
      _connectivityController.stream;
  ConnectivityStatus get currentStatus => _lastStatus;
  int get lastLatencyMs => _lastLatencyMs;

  Stream<bool> get isConnected =>
      connectivityStream.map((status) => status == ConnectivityStatus.online);

  bool get isCurrentlyConnected => _lastStatus == ConnectivityStatus.online;

  void _startConnectivityMonitoring() {
    _initialCheckTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(_runConnectivityCheck(force: true));
    });

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      unawaited(_handleConnectivityChange(results));
    });

    unawaited(
      _connectivity.checkConnectivity().then(
        (results) => _handleConnectivityChange(results),
      ),
    );
  }

  Future<void> _runConnectivityCheck({bool force = false}) async {
    if (_connectivityController.isClosed) return;

    if (!_hasNetwork) {
      _lastLatencyMs = -1;
      _updateStatus(ConnectivityStatus.offline);
      return;
    }

    _initialCheckTimer?.cancel();
    _initialCheckTimer = null;
    _cancelScheduledPoll();

    final existingCheck = _activeCheck;
    if (existingCheck != null) {
      if (force) {
        _queuedImmediateCheck = true;
      }
      await existingCheck.future;
      if (force && _queuedImmediateCheck) {
        _queuedImmediateCheck = false;
        await _runConnectivityCheck(force: false);
      }
      return;
    }

    final completer = Completer<void>();
    _activeCheck = completer;

    if (_lastStatus != ConnectivityStatus.checking) {
      _updateStatus(ConnectivityStatus.checking);
    }

    try {
      await _checkConnectivity();
    } finally {
      completer.complete();
      _activeCheck = null;
    }

    if (_queuedImmediateCheck) {
      _queuedImmediateCheck = false;
      await _runConnectivityCheck(force: false);
      return;
    }

    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (_connectivityController.isClosed || !_hasNetwork) {
      return;
    }

    _pollTimer = Timer(_interval, () {
      _pollTimer = null;
      unawaited(_runConnectivityCheck());
    });
  }

  void _cancelScheduledPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool _haveSameConnectivity(
    List<ConnectivityResult> previous,
    List<ConnectivityResult> current,
  ) {
    if (identical(previous, current)) return true;
    if (previous.length != current.length) return false;
    final previousSet = previous.toSet();
    final currentSet = current.toSet();
    if (previousSet.length != currentSet.length) return false;
    for (final value in previousSet) {
      if (!currentSet.contains(value)) return false;
    }
    return true;
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    if (_connectivityController.isClosed) return;

    final previousResults = _lastConnectivityResults;
    _lastConnectivityResults = results;
    final hadNetwork = _hasNetwork;
    _hasNetwork = results.any((result) => result != ConnectivityResult.none);

    if (!_hasNetwork) {
      _lastLatencyMs = -1;
      _queuedImmediateCheck = false;
      _cancelScheduledPoll();
      _initialCheckTimer?.cancel();
      _initialCheckTimer = null;
      _updateStatus(ConnectivityStatus.offline);
      return;
    }

    final networkTypeChanged = previousResults == null
        ? true
        : !_haveSameConnectivity(previousResults, results);

    if (!hadNetwork ||
        _lastStatus == ConnectivityStatus.offline ||
        networkTypeChanged) {
      unawaited(_runConnectivityCheck(force: true));
    }
  }

  Future<void> _checkConnectivity() async {
    if (_connectivityController.isClosed) return;

    final serverReachability = await _probeActiveServer();
    if (serverReachability != null) {
      if (serverReachability) {
        _updateStatus(ConnectivityStatus.online);
      } else {
        _lastLatencyMs = -1;
        _updateStatus(ConnectivityStatus.offline);
      }
      return;
    }

    final fallbackReachability = await _probeAnyKnownServer();
    if (fallbackReachability != null) {
      if (fallbackReachability) {
        _updateStatus(ConnectivityStatus.online);
      } else {
        _lastLatencyMs = -1;
        _updateStatus(ConnectivityStatus.offline);
      }
      return;
    }

    _lastLatencyMs = -1;
    _updateStatus(ConnectivityStatus.online);
  }

  void _updateStatus(ConnectivityStatus status) {
    if (_lastStatus != status) {
      _lastStatus = status;
      if (!_connectivityController.isClosed) {
        _connectivityController.add(status);
      }
    }

    if (status == ConnectivityStatus.offline) {
      _recentFailures = (_recentFailures + 1).clamp(0, 10);
    } else if (status == ConnectivityStatus.online) {
      _recentFailures = 0;
    }

    final newInterval = _recentFailures >= 3
        ? const Duration(seconds: 20)
        : _recentFailures == 2
        ? const Duration(seconds: 15)
        : const Duration(seconds: 10);

    if (newInterval != _interval) {
      _interval = newInterval;
      _cancelScheduledPoll();
      if (_lastStatus != ConnectivityStatus.offline && _hasNetwork) {
        _scheduleNextPoll();
      }
    }
  }

  Future<bool> checkConnectivity() async {
    await _runConnectivityCheck(force: true);
    return _lastStatus == ConnectivityStatus.online;
  }

  void dispose() {
    _initialCheckTimer?.cancel();
    _initialCheckTimer = null;
    _cancelScheduledPoll();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _activeCheck = null;
    if (!_connectivityController.isClosed) {
      _connectivityController.close();
    }
  }

  Future<bool?> _probeActiveServer() async {
    final baseUri = _resolveBaseUri();
    if (baseUri == null) return null;

    return _probeBaseEndpoint(baseUri, updateLatency: true);
  }

  Future<bool?> _probeAnyKnownServer() async {
    try {
      final configs = await _ref.read(serverConfigsProvider.future);
      for (final config in configs) {
        final uri = _buildBaseUri(config.url);
        if (uri == null) continue;
        final result = await _probeBaseEndpoint(uri);
        if (result != null) {
          return result;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool?> _probeBaseEndpoint(
    Uri baseUri, {
    bool updateLatency = false,
  }) async {
    try {
      final start = DateTime.now();
      final healthUri = baseUri.resolve('/health');
      final response = await _dio
          .getUri(
            healthUri,
            options: Options(
              method: 'GET',
              sendTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
              followRedirects: false,
              validateStatus: (status) => status != null && status < 500,
            ),
          )
          .timeout(const Duration(seconds: 4));

      final isHealthy = response.statusCode == 200;
      if (isHealthy && updateLatency) {
        _lastLatencyMs = DateTime.now().difference(start).inMilliseconds;
      }
      return isHealthy;
    } catch (_) {
      return false;
    }
  }

  Uri? _resolveBaseUri() {
    final api = _ref.read(apiServiceProvider);
    if (api != null) {
      return _buildBaseUri(api.baseUrl);
    }

    final activeServer = _ref.read(activeServerProvider);
    return activeServer.maybeWhen(
      data: (server) => server != null ? _buildBaseUri(server.url) : null,
      orElse: () => null,
    );
  }

  Uri? _buildBaseUri(String baseUrl) {
    if (baseUrl.isEmpty) return null;

    Uri? parsed = Uri.tryParse(baseUrl.trim());
    if (parsed == null) return null;

    if (!parsed.hasScheme) {
      parsed =
          Uri.tryParse('https://$baseUrl') ?? Uri.tryParse('http://$baseUrl');
    }
    if (parsed == null) return null;

    return parsed;
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final activeServer = ref.watch(activeServerProvider);

  return activeServer.maybeWhen(
    data: (server) {
      if (server == null) {
        final dio = Dio();
        final service = ConnectivityService(dio, ref);
        ref.onDispose(() => service.dispose());
        return service;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: server.url,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 400,
          headers: server.customHeaders.isNotEmpty
              ? Map<String, String>.from(server.customHeaders)
              : null,
        ),
      );

      final service = ConnectivityService(dio, ref);
      ref.onDispose(() => service.dispose());
      return service;
    },
    orElse: () {
      final dio = Dio();
      final service = ConnectivityService(dio, ref);
      ref.onDispose(() => service.dispose());
      return service;
    },
  );
});

@Riverpod(keepAlive: true)
class ConnectivityStatusNotifier extends _$ConnectivityStatusNotifier {
  StreamSubscription<ConnectivityStatus>? _subscription;

  @override
  FutureOr<ConnectivityStatus> build() {
    final service = ref.watch(connectivityServiceProvider);

    _subscription?.cancel();
    _subscription = service.connectivityStream.listen(
      (status) => state = AsyncValue.data(status),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );

    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    return service.currentStatus;
  }
}

final isOnlineProvider = Provider<bool>((ref) {
  final reviewerMode = ref.watch(reviewerModeProvider);
  if (reviewerMode) return true;
  final status = ref.watch(connectivityStatusProvider);
  return status.when(
    data: (status) => status != ConnectivityStatus.offline,
    loading: () => true,
    error: (error, _) => true,
  );
});
