import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/server_config.dart';
import '../utils/debug_logger.dart';
import 'socket_tls_override.dart';

typedef SocketChatEventHandler =
    void Function(
      Map<String, dynamic> event,
      void Function(dynamic response)? ack,
    );

typedef SocketChannelEventHandler =
    void Function(
      Map<String, dynamic> event,
      void Function(dynamic response)? ack,
    );

class SocketService with WidgetsBindingObserver {
  final ServerConfig serverConfig;
  final bool websocketOnly;
  final bool allowWebsocketUpgrade;
  io.Socket? _socket;
  String? _authToken;
  bool _isConnecting = false;
  bool _isAppForeground = true;
  Timer? _heartbeatTimer;

  /// Heartbeat interval matching OpenWebUI's 30-second interval.
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  final Map<String, _ChatEventRegistration> _chatEventHandlers = {};
  final Map<String, _ChannelEventRegistration> _channelEventHandlers = {};
  int _handlerSeed = 0;

  /// Stream controller that emits when a socket reconnection occurs.
  /// Listeners can use this to sync state after a reconnect.
  final _reconnectController = StreamController<void>.broadcast();

  /// Stream that emits when a socket reconnection occurs.
  Stream<void> get onReconnect => _reconnectController.stream;

  SocketService({
    required this.serverConfig,
    String? authToken,
    this.websocketOnly = false,
    this.allowWebsocketUpgrade = true,
  }) : _authToken = authToken {
    final binding = WidgetsBinding.instance;
    final lifecycle = binding.lifecycleState;
    _isAppForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    binding.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppForeground = state == AppLifecycleState.resumed;
  }

  String? get sessionId => _socket?.id;
  io.Socket? get socket => _socket;
  String? get authToken => _authToken;

  bool get isConnected => _socket?.connected == true;
  bool get isAppForeground => _isAppForeground;

  Future<void> connect({bool force = false}) async {
    if (_socket != null && _socket!.connected && !force) return;
    if (_isConnecting && !force) return;

    _isConnecting = true;

    DebugLogger.log(
      'Connecting to socket',
      scope: 'socket',
      data: {'force': force, 'serverUrl': serverConfig.url},
    );

    // Stop any existing heartbeat before disposing old socket
    _stopHeartbeat();

    try {
      final existing = _socket;
      if (existing != null) {
        _unbindCoreSocketHandlers(existing);
        existing.dispose();
      }
    } catch (_) {}

    String base = serverConfig.url.replaceFirst(RegExp(r'/+$'), '');
    // Normalize accidental ":0" ports or invalid port values in stored URL
    try {
      final u = Uri.parse(base);
      if (u.hasPort && u.port == 0) {
        // Drop the explicit :0 to fall back to scheme default (80/443)
        base = '${u.scheme}://${u.host}${u.path.isEmpty ? '' : u.path}';
      }
    } catch (_) {}
    final path = '/ws/socket.io';

    final usePollingOnly = !websocketOnly && !allowWebsocketUpgrade;
    final transports = websocketOnly
        ? const ['websocket']
        : usePollingOnly
        ? const ['polling']
        : const ['polling', 'websocket'];

    final builder = io.OptionBuilder()
        // Transport selection switches between WebSocket-only and polling fallback
        .setTransports(transports)
        .setRememberUpgrade(!websocketOnly && allowWebsocketUpgrade)
        .setUpgrade(!websocketOnly && allowWebsocketUpgrade)
        // Tune reconnect/backoff and timeouts
        // Note: In socket_io_client, pass a very large number for "unlimited" attempts.
        // Using double.maxFinite.toInt() ensures unlimited reconnection attempts.
        .setReconnectionAttempts(double.maxFinite.toInt())
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000)
        .setRandomizationFactor(0.5)
        .setTimeout(20000)
        .setPath(path);

    // Merge Authorization (if any) with user-defined custom headers for the
    // Socket.IO handshake. Avoid overriding reserved headers.
    final Map<String, String> extraHeaders = {};
    if (_authToken != null && _authToken!.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $_authToken';
      builder.setAuth({'token': _authToken});
    }
    if (serverConfig.customHeaders.isNotEmpty) {
      final reserved = {
        'authorization',
        'content-type',
        'accept',
        // Socket/WebSocket reserved or managed by client/runtime
        'host',
        'origin',
        'connection',
        'upgrade',
        'sec-websocket-key',
        'sec-websocket-version',
        'sec-websocket-extensions',
        'sec-websocket-protocol',
      };
      serverConfig.customHeaders.forEach((key, value) {
        final lower = key.toLowerCase();
        if (!reserved.contains(lower) && value.isNotEmpty) {
          // Do not overwrite Authorization we already set from authToken
          if (lower == 'authorization' &&
              extraHeaders.containsKey('Authorization')) {
            return;
          }
          extraHeaders[key] = value;
        }
      });
    }
    if (extraHeaders.isNotEmpty) {
      builder.setExtraHeaders(extraHeaders);
    }

    try {
      _socket = createSocketWithOptionalBadCertOverride(
        base,
        builder,
        serverConfig,
      );
      _bindCoreSocketHandlers();
    } catch (_) {
      _isConnecting = false;
      rethrow;
    }
  }

  /// Update the auth token used by the socket service.
  /// If connected, emits a best-effort rejoin with the new token.
  void updateAuthToken(String? token) {
    _authToken = token;
    if (_socket?.connected == true &&
        _authToken != null &&
        _authToken!.isNotEmpty) {
      try {
        _socket!.emit('user-join', {
          'auth': {'token': _authToken},
        });
      } catch (_) {}
    }
  }

  SocketEventSubscription addChatEventHandler({
    String? conversationId,
    String? sessionId,
    bool requireFocus = true,
    required SocketChatEventHandler handler,
  }) {
    final id = _nextHandlerId();
    _chatEventHandlers[id] = _ChatEventRegistration(
      id: id,
      conversationId: conversationId,
      sessionId: sessionId,
      requireFocus: requireFocus,
      handler: handler,
    );
    return SocketEventSubscription(
      () => _chatEventHandlers.remove(id),
      handlerId: id,
    );
  }

  SocketEventSubscription addChannelEventHandler({
    String? conversationId,
    String? sessionId,
    bool requireFocus = true,
    required SocketChannelEventHandler handler,
  }) {
    final id = _nextHandlerId();
    _channelEventHandlers[id] = _ChannelEventRegistration(
      id: id,
      conversationId: conversationId,
      sessionId: sessionId,
      requireFocus: requireFocus,
      handler: handler,
    );
    return SocketEventSubscription(
      () => _channelEventHandlers.remove(id),
      handlerId: id,
    );
  }

  void clearChatEventHandlers() {
    _chatEventHandlers.clear();
  }

  void clearChannelEventHandlers() {
    _channelEventHandlers.clear();
  }

  /// Update the session ID for a chat event handler registration.
  /// Used when socket reconnects and gets a new session ID.
  void updateChatHandlerSessionId(String handlerId, String newSessionId) {
    final existing = _chatEventHandlers[handlerId];
    if (existing != null) {
      _chatEventHandlers[handlerId] = _ChatEventRegistration(
        id: existing.id,
        conversationId: existing.conversationId,
        sessionId: newSessionId,
        requireFocus: existing.requireFocus,
        handler: existing.handler,
      );
    }
  }

  /// Update the session ID for a channel event handler registration.
  /// Used when socket reconnects and gets a new session ID.
  void updateChannelHandlerSessionId(String handlerId, String newSessionId) {
    final existing = _channelEventHandlers[handlerId];
    if (existing != null) {
      _channelEventHandlers[handlerId] = _ChannelEventRegistration(
        id: existing.id,
        conversationId: existing.conversationId,
        sessionId: newSessionId,
        requireFocus: existing.requireFocus,
        handler: existing.handler,
      );
    }
  }

  /// Update session IDs for all handlers matching a conversation ID.
  /// Called after socket reconnection to update handlers with the new session.
  void updateSessionIdForConversation(
    String conversationId,
    String newSessionId,
  ) {
    for (final entry in _chatEventHandlers.entries.toList()) {
      if (entry.value.conversationId == conversationId) {
        _chatEventHandlers[entry.key] = _ChatEventRegistration(
          id: entry.value.id,
          conversationId: entry.value.conversationId,
          sessionId: newSessionId,
          requireFocus: entry.value.requireFocus,
          handler: entry.value.handler,
        );
      }
    }
    for (final entry in _channelEventHandlers.entries.toList()) {
      if (entry.value.conversationId == conversationId) {
        _channelEventHandlers[entry.key] = _ChannelEventRegistration(
          id: entry.value.id,
          conversationId: entry.value.conversationId,
          sessionId: newSessionId,
          requireFocus: entry.value.requireFocus,
          handler: entry.value.handler,
        );
      }
    }
  }

  // Subscribe to an arbitrary socket.io event (used for dynamic tool channels)
  void onEvent(String eventName, void Function(dynamic data) handler) {
    _socket?.on(eventName, handler);
  }

  void offEvent(String eventName) {
    _socket?.off(eventName);
  }

  void dispose() {
    _stopHeartbeat();
    try {
      final existing = _socket;
      if (existing != null) {
        _unbindCoreSocketHandlers(existing);
        existing.dispose();
      }
    } catch (_) {}
    _socket = null;
    WidgetsBinding.instance.removeObserver(this);
    _chatEventHandlers.clear();
    _channelEventHandlers.clear();
    _reconnectController.close();
  }

  // Best-effort: ensure there is an active connection and wait briefly.
  // Returns true if connected by the end of the timeout.
  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (isConnected) return true;
    try {
      await connect();
    } catch (_) {}
    final start = DateTime.now();
    while (!isConnected && DateTime.now().difference(start) < timeout) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return isConnected;
  }

  void _bindCoreSocketHandlers() {
    final socket = _socket;
    if (socket == null) return;

    _unbindCoreSocketHandlers(socket);

    socket
      ..on('events', _handleChatEvent)
      ..on('chat-events', _handleChatEvent)
      ..on('events:channel', _handleChannelEvent)
      ..on('channel-events', _handleChannelEvent)
      ..on('connect', _handleConnect)
      ..on('connect_error', _handleConnectError)
      ..on('reconnect_attempt', _handleReconnectAttempt)
      ..on('reconnect', _handleReconnect)
      ..on('reconnect_failed', _handleReconnectFailed)
      ..on('disconnect', _handleDisconnect);
  }

  void _unbindCoreSocketHandlers(io.Socket socket) {
    socket
      ..off('events', _handleChatEvent)
      ..off('chat-events', _handleChatEvent)
      ..off('events:channel', _handleChannelEvent)
      ..off('channel-events', _handleChannelEvent)
      ..off('connect', _handleConnect)
      ..off('connect_error', _handleConnectError)
      ..off('reconnect_attempt', _handleReconnectAttempt)
      ..off('reconnect', _handleReconnect)
      ..off('reconnect_failed', _handleReconnectFailed)
      ..off('disconnect', _handleDisconnect);
  }

  void _handleConnect(dynamic _) {
    _isConnecting = false;
    DebugLogger.log(
      'Socket connected',
      scope: 'socket',
      data: {'sessionId': _socket?.id},
    );

    if (_authToken != null && _authToken!.isNotEmpty) {
      _socket?.emit('user-join', {
        'auth': {'token': _authToken},
      });
    }

    // Start heartbeat timer to keep connection alive
    _startHeartbeat();
  }

  void _handleReconnectAttempt(dynamic attempt) {
    _isConnecting = true;
    DebugLogger.log(
      'Socket reconnection attempt',
      scope: 'socket',
      data: {'attempt': attempt},
    );
  }

  void _handleReconnect(dynamic attempt) {
    _isConnecting = false;
    DebugLogger.log(
      'Socket reconnected',
      scope: 'socket',
      data: {'attempt': attempt, 'sessionId': _socket?.id},
    );

    if (_authToken != null && _authToken!.isNotEmpty) {
      _socket?.emit('user-join', {
        'auth': {'token': _authToken},
      });
    }

    // Restart heartbeat after reconnection
    _startHeartbeat();

    // Notify listeners that a reconnection occurred so they can refresh state
    if (!_reconnectController.isClosed) {
      _reconnectController.add(null);
    }
  }

  void _handleConnectError(dynamic err) {
    _isConnecting = false;
    DebugLogger.error(
      'Socket connection error',
      scope: 'socket',
      error: err,
      data: {'serverUrl': serverConfig.url},
    );
  }

  void _handleReconnectFailed(dynamic _) {
    _isConnecting = false;
    DebugLogger.error(
      'Socket reconnection failed after all attempts',
      scope: 'socket',
      data: {'serverUrl': serverConfig.url},
    );
  }

  void _handleDisconnect(dynamic reason) {
    _isConnecting = false;
    DebugLogger.warning(
      'Socket disconnected',
      scope: 'socket',
      data: {'reason': reason?.toString()},
    );

    // Stop heartbeat when disconnected
    _stopHeartbeat();
  }

  /// Starts the heartbeat timer to keep the connection alive.
  /// Sends a heartbeat event every 30 seconds matching OpenWebUI's behavior.
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_socket?.connected == true) {
        _socket?.emit('heartbeat', <String, dynamic>{});
      }
    });
  }

  /// Stops the heartbeat timer.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _handleChatEvent(dynamic data, [dynamic ack]) {
    final map = _coerceToMap(data);
    if (map == null) return;

    final ackFn = _wrapAck(ack);
    final sessionId = _extractSessionId(map);
    final chatId = map['chat_id']?.toString();
    final channelId = _extractChannelId(map);

    for (final registration in List<_ChatEventRegistration>.from(
      _chatEventHandlers.values,
    )) {
      if (!_shouldDeliver(
        registration.conversationId,
        registration.sessionId,
        chatId,
        sessionId,
        registration.requireFocus,
        incomingChannelId: channelId,
      )) {
        continue;
      }

      try {
        registration.handler(map, ackFn);
      } catch (_) {}
    }
  }

  void _handleChannelEvent(dynamic data, [dynamic ack]) {
    final map = _coerceToMap(data);
    if (map == null) return;

    final ackFn = _wrapAck(ack);
    final sessionId = _extractSessionId(map);
    final chatId = map['chat_id']?.toString();
    final channelId = _extractChannelId(map);

    for (final registration in List<_ChannelEventRegistration>.from(
      _channelEventHandlers.values,
    )) {
      if (!_shouldDeliver(
        registration.conversationId,
        registration.sessionId,
        chatId,
        sessionId,
        registration.requireFocus,
        incomingChannelId: channelId,
      )) {
        continue;
      }

      try {
        registration.handler(map, ackFn);
      } catch (_) {}
    }
  }

  bool _shouldDeliver(
    String? registeredConversationId,
    String? registeredSessionId,
    String? incomingConversationId,
    String? incomingSessionId,
    bool requireFocus, {
    String? incomingChannelId,
  }) {
    final matchesConversation =
        registeredConversationId == null ||
        (incomingConversationId != null &&
            registeredConversationId == incomingConversationId) ||
        (incomingChannelId != null &&
            registeredConversationId == incomingChannelId);
    final matchesSession =
        registeredSessionId != null &&
        incomingSessionId != null &&
        registeredSessionId == incomingSessionId;

    // Must match either conversation or session to be considered
    if (!matchesConversation && !matchesSession) {
      return false;
    }

    // If no focus requirement, always deliver
    if (!requireFocus) {
      return true;
    }

    // Session-targeted messages always bypass focus check (critical for
    // background streaming - done/delta events must arrive even when backgrounded)
    if (matchesSession) {
      return true;
    }

    // FIX for issue #172: If conversation matches (even without session match),
    // still deliver when app is in foreground. This handles socket reconnection
    // where session_id changes but chat_id stays the same.
    if (matchesConversation && registeredConversationId != null) {
      return _isAppForeground;
    }

    return _isAppForeground;
  }

  Map<String, dynamic>? _coerceToMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  void Function(dynamic response)? _wrapAck(dynamic ack) {
    if (ack is! Function) return null;
    return (dynamic payload) {
      try {
        if (payload is List) {
          Function.apply(ack, payload);
        } else if (payload == null) {
          Function.apply(ack, const []);
        } else {
          Function.apply(ack, [payload]);
        }
      } catch (_) {}
    };
  }

  String? _extractSessionId(Map<String, dynamic> event) {
    String? candidate;

    if (event['session_id'] != null) {
      candidate = event['session_id'].toString();
    }

    final data = event['data'];
    if (data is Map) {
      if (candidate == null && data['session_id'] != null) {
        candidate = data['session_id'].toString();
      }
      if (candidate == null && data['sessionId'] != null) {
        candidate = data['sessionId'].toString();
      }
      final inner = data['data'];
      if (inner is Map) {
        if (candidate == null && inner['session_id'] != null) {
          candidate = inner['session_id'].toString();
        }
        if (candidate == null && inner['sessionId'] != null) {
          candidate = inner['sessionId'].toString();
        }
      }
    }

    return candidate;
  }

  String? _extractChannelId(Map<String, dynamic> event) {
    String? candidate;

    if (event['channel_id'] != null) {
      candidate = event['channel_id'].toString();
    }
    if (candidate == null && event['channelId'] != null) {
      candidate = event['channelId'].toString();
    }

    final data = event['data'];
    if (data is Map) {
      if (candidate == null && data['channel_id'] != null) {
        candidate = data['channel_id'].toString();
      }
      if (candidate == null && data['channelId'] != null) {
        candidate = data['channelId'].toString();
      }
      final inner = data['data'];
      if (inner is Map) {
        if (candidate == null && inner['channel_id'] != null) {
          candidate = inner['channel_id'].toString();
        }
        if (candidate == null && inner['channelId'] != null) {
          candidate = inner['channelId'].toString();
        }
      }
    }

    return candidate;
  }

  String _nextHandlerId() {
    _handlerSeed += 1;
    return _handlerSeed.toString();
  }
}

class SocketEventSubscription {
  SocketEventSubscription(this._dispose, {this.handlerId});

  final VoidCallback _dispose;
  final String? handlerId;
  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _dispose();
  }
}

class _ChatEventRegistration {
  _ChatEventRegistration({
    required this.id,
    required this.handler,
    this.conversationId,
    this.sessionId,
    this.requireFocus = true,
  });

  final String id;
  final String? conversationId;
  final String? sessionId;
  final bool requireFocus;
  final SocketChatEventHandler handler;
}

class _ChannelEventRegistration {
  _ChannelEventRegistration({
    required this.id,
    required this.handler,
    this.conversationId,
    this.sessionId,
    this.requireFocus = true,
  });

  final String id;
  final String? conversationId;
  final String? sessionId;
  final bool requireFocus;
  final SocketChannelEventHandler handler;
}
