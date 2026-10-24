import 'dart:typed_data';

import 'package:conduit_core/conduit_core.dart';

/// The app's [AudioCapturePort] when no microphone is used.
///
/// Clinical Guidelines declares no microphone, speech or call permissions, so
/// capture is never available and never starts.
class NoAudioCapture implements AudioCapturePort {
  NoAudioCapture();

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> manageIosAudioSession(bool manage) async {}

  @override
  Future<Stream<Uint8List>> startStream(AudioCaptureConfig config) =>
      Future.error(StateError('Audio capture is not available.'));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
