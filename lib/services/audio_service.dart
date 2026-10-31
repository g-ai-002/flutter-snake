import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'log_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final _player = AudioPlayer();
  final _bgmPlayer = AudioPlayer();
  final Map<String, Uint8List> _toneCache = {};
  Uint8List? _bgmLoop;
  bool _muted = false;
  bool _bgmRequested = false;
  bool _bgmPlaying = false;

  bool get muted => _muted;

  void setMuted(bool v) {
    _muted = v;
    LogService.info('音效: ${v ? "静音" : "开启"}');
    if (!_bgmRequested) return;
    if (v) {
      _guard(_bgmPlayer.pause());
    } else if (_bgmPlaying) {
      _guard(_bgmPlayer.resume());
    } else {
      startBgm();
    }
  }

  /// 预生成常用音效并预热播放器，避免第一次吃食物时卡顿。
  void prewarm() {
    _tone(660, 80);
    _tone(220, 200);
    _tone(165, 400);
    _tone(880, 90);
    _tone(1175, 110);
    _tone(300, 140);
    _bgmLoop ??= _generateBgmLoop();
    _guard(_player.setVolume(1.0));
  }

  /// 开始循环播放背景音乐；静音时只记录请求，取消静音后再播放。
  void startBgm() {
    _bgmRequested = true;
    _bgmLoop ??= _generateBgmLoop();
    if (_muted || _bgmPlaying) return;
    _guard(_playBgm());
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

  Future<void> playPowerUp() async {
    if (_muted) return;
    await _playTone(880, 90);
    await Future.delayed(const Duration(milliseconds: 70));
    await _playTone(1175, 110);
  }

  Future<void> playShieldBreak() async {
    if (_muted) return;
    await _playTone(300, 140);
  }

  Future<void> _playTone(int freq, int durationMs) async {
    try {
      await _player.play(BytesSource(_tone(freq, durationMs)));
    } catch (e) {
      LogService.warning('音效播放失败: $e');
    }
  }

  Future<void> _playBgm() async {
    if (!_bgmRequested || _muted) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.35);
      await _bgmPlayer.play(BytesSource(_bgmLoop!));
      _bgmPlaying = true;
    } catch (e) {
      _bgmPlaying = false;
      LogService.warning('背景音乐播放失败: $e');
    }
  }

  Future<void> _guard(Future<void> future) async {
    try {
      await future;
    } catch (e) {
      LogService.warning('音效操作失败: $e');
    }
  }

  Uint8List _tone(int freq, int durationMs) {
    return _toneCache.putIfAbsent(
      '$freq:$durationMs',
      () => _generateWav(freq, durationMs),
    );
  }

  Uint8List _generateWav(int freq, int durationMs) {
    const sampleRate = 22050;
    final numSamples = (sampleRate * durationMs / 1000).round();
    return _buildWav(sampleRate, numSamples, (i) {
      final t = i / sampleRate;
      final envelope = 1.0 - (i / numSamples);
      return sin(2 * pi * freq * t) * envelope * 0.3;
    });
  }

  Uint8List _generateBgmLoop() {
    const sampleRate = 22050;
    const durationMs = 8000;
    const noteDuration = 0.5;
    const notes = [261.63, 329.63, 392.00, 523.25];
    const numSamples = sampleRate * durationMs ~/ 1000;
    return _buildWav(sampleRate, numSamples, (i) {
      final t = i / sampleRate;
      final noteIndex = (t / noteDuration).floor() % notes.length;
      final noteT = t % noteDuration;
      final envelope = sin(pi * noteT / noteDuration);
      final melody = sin(2 * pi * notes[noteIndex] * t) * envelope * 0.08;
      final bass = sin(2 * pi * 130.81 * t) * 0.025;
      return melody + bass;
    });
  }

  Uint8List _buildWav(
    int sampleRate,
    int numSamples,
    double Function(int index) sampleAt,
  ) {
    const channels = 1;
    const bitsPerSample = 16;
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

    for (var i = 0; i < numSamples; i++) {
      final sample = (sampleAt(i) * 32767).round().clamp(-32768, 32767).toInt();
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _player.dispose();
    _bgmPlayer.dispose();
  }
}
