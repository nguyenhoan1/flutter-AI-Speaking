import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper đơn giản quanh flutter_tts để đọc text tiếng Anh.
/// Chỉ giữ 1 instance singleton trong app.
class TtsService {
  TtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _enabled = true;

  bool get isEnabled => _enabled;

  /// Bật/tắt TTS. Khi tắt sẽ dừng đọc nếu đang đọc.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) await stop();
  }

  Future<void> _init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // 0.5 là tốc độ tự nhiên dễ nghe
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      // iOS — share audio session với background.
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Đọc một đoạn text. Tự động bỏ qua khi tắt hoặc text rỗng.
  Future<void> speak(String text) async {
    if (!_enabled) return;
    final clean = _stripForSpeech(text);
    if (clean.isEmpty) return;
    if (!_ready) {
      await _init();
    }
    try {
      await _tts.stop();
      await _tts.speak(clean);
    } catch (_) {
      // im lặng — TTS không phải critical path
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Bỏ markdown, emoji, ký tự thừa để TTS đọc tự nhiên hơn.
  String _stripForSpeech(String text) {
    var t = text;
    // Bỏ markdown bold/italic
    t = t.replaceAll(RegExp(r'\*+'), '');
    // Bỏ code fence
    t = t.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    t = t.replaceAll('`', '');
    // Bỏ emoji thông dụng (regex đơn giản: ký tự ngoài BMP)
    t = t.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );
    return t.trim();
  }
}
