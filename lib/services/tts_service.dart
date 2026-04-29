import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String _currentLanguage = '';

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(kIsWeb ? 0.8 : 0.5); // 웹은 좀 더 빠르게

    // 웹에서 완료 핸들러
    _tts.setCompletionHandler(() {});

    _initialized = true;
  }

  Future<void> speak(String text, String language) async {
    await init();

    final lang = language == 'kor' ? 'ko-KR' : 'en-US';

    // 언어가 바뀔 때만 setLanguage 호출 (매번 호출 안 함)
    if (_currentLanguage != lang) {
      await _tts.setLanguage(lang);
      _currentLanguage = lang;
    }

    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}