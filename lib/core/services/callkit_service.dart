import 'dart:developer' as developer;

import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'callkit_service.g.dart';

/// Thin wrapper around `flutter_callkit_incoming` for voice calls.
class CallKitService {
  CallKitService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  static const int _defaultCallDurationMs = 2 * 60 * 60 * 1000; // 2 hours

  /// Requests the notification/full-screen intent permissions needed on Android.
  Future<void> requestPermissions() async {
    await _safe(
      () => FlutterCallkitIncoming.requestNotificationPermission(
        <String, dynamic>{
          'title': 'Notification permission',
          'rationaleMessagePermission':
              'Call alerts need notification permission.',
          'postNotificationMessageRequired':
              'Allow notifications to show incoming calls.',
        },
      ),
    );
    // Full-screen intent permission not needed for outgoing-only calls.
  }

  /// Starts an outgoing call with the native UI and returns the call id.
  Future<String?> startOutgoingVoiceCall({
    required String calleeName,
    required String handle,
    String? avatar,
    int? durationMs,
  }) async {
    final id = _uuid.v4();
    final params = _buildParams(
      id: id,
      callerName: calleeName,
      handle: handle,
      avatar: avatar,
      durationMs: durationMs ?? _defaultCallDurationMs,
    );
    try {
      await FlutterCallkitIncoming.startCall(params);
      return id;
    } catch (error, stackTrace) {
      developer.log(
        'CallKit startCall failed: $error',
        name: 'callkit',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Marks the current call as connected so iOS shows an incrementing timer.
  Future<void> markCallConnected(String id) async {
    try {
      await FlutterCallkitIncoming.setCallConnected(id);
    } catch (error, stackTrace) {
      developer.log(
        'CallKit setCallConnected failed: $error',
        name: 'callkit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Ends a specific call id.
  Future<void> endCall(String id) async {
    await _safe(() => FlutterCallkitIncoming.endCall(id));
  }

  /// Clears all ongoing/missed calls.
  Future<void> endAllCalls() async {
    await _safe(FlutterCallkitIncoming.endAllCalls);
  }

  /// Returns the platform VOIP token (iOS PushKit) when available.
  Future<String?> getVoipToken() async {
    final token = await _safe<dynamic>(
      () => FlutterCallkitIncoming.getDevicePushTokenVoIP(),
    );
    if (token == null) return null;
    if (token is String) return token;
    return token.toString();
  }

  /// Returns the raw active call list from the plugin.
  Future<List<Map<String, dynamic>>> activeCalls() async {
    final calls = await _safe<dynamic>(FlutterCallkitIncoming.activeCalls);
    if (calls is List) {
      return calls
          .whereType<Map<dynamic, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// Stream of CallKit events from the native layer.
  Stream<CallEvent> get events =>
      FlutterCallkitIncoming.onEvent.where((event) => event != null).cast();

  CallKitParams _buildParams({
    required String id,
    required String callerName,
    required String handle,
    String? avatar,
    int durationMs = _defaultCallDurationMs,
  }) {
    return CallKitParams(
      id: id,
      nameCaller: callerName,
      appName: 'Conduit',
      avatar: avatar,
      handle: handle,
      type: 0, // 0 = audio call
      duration: durationMs,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Calling...',
        callbackText: 'Hang up',
      ),
      extra: const <String, dynamic>{'transport': 'voice'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0D1726',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
  }

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      developer.log(
        'CallKit error: $error',
        name: 'callkit',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
CallKitService callKitService(Ref ref) => CallKitService();
