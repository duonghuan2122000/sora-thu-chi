import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/data/platform/device_probe_platform.dart';
import 'package:sora_thu_chi/data/platform/gemini_nano_llm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodCall? lastCall;

  void setHandler(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kDeviceProbeChannel, (call) async {
      lastCall = call;
      return handler(call);
    });
  }

  tearDown(() {
    lastCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kDeviceProbeChannel, null);
  });

  test('engine = geminiNano, supportsImage = true', () {
    const llm = GeminiNanoLlm();
    expect(llm.engine, ScanEngine.geminiNano);
    expect(llm.supportsImage, isTrue);
  });

  test('có ảnh ⇒ gọi genAiGenerate kèm key "image" đúng bytes (PBI 37)', () async {
    final image = Uint8List.fromList([1, 2, 3]);
    setHandler((_) async => '{"amount": 55000}');
    const llm = GeminiNanoLlm();

    final result = await llm.generate('prompt-test', image: image);

    expect(result, '{"amount": 55000}');
    expect(lastCall!.method, 'genAiGenerate');
    expect(lastCall!.arguments['prompt'], 'prompt-test');
    expect(lastCall!.arguments['image'], image);
  });

  test('không có ảnh ⇒ gọi genAiGenerate không kèm key "image" (hành vi cũ)', () async {
    setHandler((_) async => '{"amount": 55000}');
    const llm = GeminiNanoLlm();

    await llm.generate('prompt-test');

    expect(lastCall!.arguments.containsKey('image'), isFalse);
  });

  test('kênh trả rỗng ⇒ ném lỗi để LlmExtractor rơi về bộ luật', () async {
    setHandler((_) async => '');
    const llm = GeminiNanoLlm();

    expect(() => llm.generate('prompt-test'), throwsStateError);
  });
}
