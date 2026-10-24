import 'package:conduit_core/features/notes/services/audio_recording_service.dart';
import 'package:path_provider/path_provider.dart';

export 'package:conduit_core/features/notes/services/audio_recording_service.dart';

/// Clinical Guidelines declares no microphone permission, so a note can never
/// be recorded: [hasPermission] is always false and nothing starts.
class UnavailableNoteAudioRecorder implements NoteAudioRecorder {
  @override
  String get fileExtension => 'm4a';

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> start(String path) =>
      Future.error(StateError('Audio recording is not available.'));

  @override
  Future<String?> stop() async => null;

  @override
  Stream<double> amplitudeChanges(Duration interval) => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

class _NoBackgroundCoordinator implements AudioRecordingBackgroundCoordinator {
  @override
  Future<bool> startMicrophoneLease() async => false;

  @override
  Future<void> stopMicrophoneLease() async {}
}

/// The note recording service with no recorder behind it.
AudioRecordingService createNoteAudioRecordingService() =>
    AudioRecordingService(
      recorder: UnavailableNoteAudioRecorder(),
      backgroundCoordinator: _NoBackgroundCoordinator(),
      temporaryDirectoryProvider: getTemporaryDirectory,
    );
