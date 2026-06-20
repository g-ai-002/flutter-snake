import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'log_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final _player = AudioPlayer();
  bool _muted = false;

  bool get muted => _muted;

  void setMuted(bool v) {
    _muted = v;
    LogService.info('音效: ${v ? "静音" : "开启"}');
  }

  Future<void> playEat() async {
    if (_muted) return;
    await _playTone(660, 80);
  }

  Future<void> playGameOver() async {
    if (_muted) return;
    await _playTone(220, 200);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(165, 400);
  }

  Future<void> _playTone(int freq, int durationMs) async {
    try {
      final wav = _generateWav(freq, durationMs);
      await _player.play(BytesSource(wav));
    } catch (e) {
      LogService.warning('音效播放失败: $e');
    }
  }

  Uint8List _generateWav(int freq, int durationMs) {
    const sampleRate = 22050;
    const channels = 1;
    const bitsPerSample = 16;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * channels * (bitsPerSample ~/ 8);
    final fileSize = 44 + dataSize;

    final buffer = ByteData(fileSize);
    var offset = 0;

    void writeStr(String s) {
      for (var i = 0; i < s.length; i++) {
        buffer.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    void writeUint16(int v) {
      buffer.setUint16(offset, v, Endian.little);
      offset += 2;
    }

    void writeUint32(int v) {
      buffer.setUint32(offset, v, Endian.little);
      offset += 4;
    }

    // RIFF header
    writeStr('RIFF');
    writeUint32(fileSize - 8);
    writeStr('WAVE');

    // fmt chunk
    writeStr('fmt ');
    writeUint32(16);
    writeUint16(1); // PCM
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(sampleRate * channels * (bitsPerSample ~/ 8));
    writeUint16(channels * (bitsPerSample ~/ 8));
    writeUint16(bitsPerSample);

    // data chunk
    writeStr('data');
    writeUint32(dataSize);

    // samples
    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = 1.0 - (i / numSamples);
      final sample = (sin(2 * pi * freq * t) * envelope * 0.3 * 32767).round();
      buffer.setInt16(offset, sample.clamp(-32768, 32767), Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _player.dispose();
  }
}
