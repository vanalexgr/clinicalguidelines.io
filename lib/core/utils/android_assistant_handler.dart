import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final androidAssistantProvider = Provider(
  (ref) => AndroidAssistantHandler(ref),
);

final screenContextProvider = NotifierProvider<ScreenContextNotifier, String?>(
  ScreenContextNotifier.new,
);

class ScreenContextNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setContext(String? context) {
    state = context;
  }
}

class AndroidAssistantHandler {
  static const platform = MethodChannel('app.cogwheel.conduit/assistant');
  final Ref _ref;

  AndroidAssistantHandler(this._ref) {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'analyzeScreen') {
      final String context = call.arguments as String;
      _ref.read(screenContextProvider.notifier).setContext(context);
    }
  }
}
