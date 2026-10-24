import 'dart:async';
import 'dart:typed_data';

/// One analysed audio frame.
class VadFrame {
  const VadFrame(this.frame);
  final List<double> frame;
}

/// Stand-in for the `vad` plugin, which Clinical Guidelines does not ship:
/// the app has no voice features, so it never listens to the microphone.
class VadHandler {
  VadHandler._();

  static VadHandler create() => VadHandler._();

  Stream<List<double>> get onSpeechEnd => const Stream.empty();
  Stream<VadFrame> get onFrameProcessed => const Stream.empty();
  Stream<String> get onError => const Stream.empty();

  Future<void> startListening({
    int? frameSamples,
    String? model,
    String? baseAssetPath,
    int? minSpeechFrames,
    int? preSpeechPadFrames,
    int? redemptionFrames,
    int? endSpeechPadFrames,
    double? positiveSpeechThreshold,
    double? negativeSpeechThreshold,
    bool? submitUserSpeechOnPause,
    Stream<Uint8List>? audioStream,
  }) async {}

  Future<void> stopListening() async {}

  Future<void> dispose() async {}
}
