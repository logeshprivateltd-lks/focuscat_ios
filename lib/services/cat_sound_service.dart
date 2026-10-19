// lib/services/cat_sound_service.dart
// Sound manager, synthesized cat audio & interactive voice (TTS) for FocusCat.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CatSoundService {
  CatSoundService._();
  static final CatSoundService instance = CatSoundService._();
  factory CatSoundService() => instance;

  bool soundEnabled = true;
  bool voiceEnabled = true;
  double volume = 0.8; // 0.0 to 1.0

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _isTtsInitialized = false;

  // Cached synthesized sound bytes
  Uint8List? _purrWav;
  Uint8List? _meowWav;
  Uint8List? _chirpWav;
  Uint8List? _curiousMewWav;
  Uint8List? _chimeWav;
  Uint8List? _swatWav;
  Uint8List? _waterWav;
  Uint8List? _clickWav;

  Future<void> init() async {
    _precomputeSounds();
    await _initTts();
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;
    try {
      if (!kIsWeb && Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
        );
        try {
          await AudioPlayer.global.setAudioContext(
            AudioContext(
              iOS: AudioContextIOS(
                category: AVAudioSessionCategory.playback,
                options: {
                  AVAudioSessionOptions.mixWithOthers,
                  AVAudioSessionOptions.defaultToSpeaker,
                },
              ),
            ),
          );
        } catch (_) {}
      }
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('[CatSoundService] audio init: $e');
    }
  }

  /// Plays authentic cat vocalizations instead of reading text/terms in a robotic voice.
  /// Categorizes text context and emits cute feline sounds (meows, purrs, chirps, curious mews).
  Future<void> speak(String text) async {
    if (!soundEnabled || !voiceEnabled) return;
    try {
      final lower = text.toLowerCase();
      if (lower.contains('purr') || lower.contains('♥') || lower.contains('pat') || lower.contains('cuddle')) {
        playPurr();
      } else if (lower.contains('swat') || lower.contains('stop') || lower.contains('blocked') || lower.contains('distract') || lower.contains('over quota')) {
        playSwat();
      } else if (lower.contains('water') || lower.contains('drink') || lower.contains('hydrate')) {
        playWaterDrop();
      } else if (lower.contains('focus') || lower.contains('pomodoro') || lower.contains('started') || lower.contains('done') || lower.contains('complete')) {
        playTimerChime();
      } else if (lower.contains('?') || lower.contains('battery') || lower.contains('weather') || lower.contains('memory') || lower.contains('status') || lower.contains('time')) {
        playCuriousMew();
      } else {
        // Cheerful friendly greeting / reply
        playChirp();
      }
    } catch (e) {
      debugPrint('[CatSoundService] speak vocalization error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Sound Effects
  // ---------------------------------------------------------------------------

  /// Single-tap (Pat): Soft Purr sound + rhythmic soft haptic vibrations
  void playPurr() {
    if (!soundEnabled) return;
    HapticFeedback.selectionClick();
    Future.delayed(const Duration(milliseconds: 140), () {
      HapticFeedback.selectionClick();
    });
    Future.delayed(const Duration(milliseconds: 280), () {
      HapticFeedback.selectionClick();
    });
    _purrWav ??= _generatePurrWav();
    _playAssetOrWav('purr', _purrWav!);
  }

  /// Double-tap (Chat / Greet): Cute Meow sound + light haptic
  void playMeow() {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    _meowWav ??= _generateMeowWav();
    _playAssetOrWav('meow', _meowWav!);
  }

  /// Cheerful cat chirp / "mrrp" greeting trill + light haptic
  void playChirp() {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    _chirpWav ??= _generateChirpWav();
    _playAssetOrWav('chirp', _chirpWav!);
  }

  /// Curious kitten questioning "mew?" + soft haptic
  void playCuriousMew() {
    if (!soundEnabled) return;
    HapticFeedback.selectionClick();
    _curiousMewWav ??= _generateCuriousMewWav();
    _playAssetOrWav('meow', _curiousMewWav!);
  }

  /// Timer Complete / Water Reminder: Pleasant Bell Chime + Meow sound
  void playTimerChime() {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    _chimeWav ??= _generateBellChimeWav();
    _playAssetOrWav('chime', _chimeWav!);
  }

  /// Tab Swat (`confront` / `angry`): Quick Angry Meow / Swat sound + heavy impact
  void playSwat() {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    _swatWav ??= _generateAngrySwatWav();
    _playAssetOrWav('swat', _swatWav!);
  }

  /// Refreshing water drop chime
  void playWaterDrop() {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    _waterWav ??= _generateWaterDropWav();
    _playAssetOrWav('water', _waterWav!);
  }

  /// Subtle UI click
  void playClick() {
    if (!soundEnabled) return;
    HapticFeedback.selectionClick();
    _clickWav ??= _generateClickWav();
    _playWav(_clickWav!);
  }

  // ---------------------------------------------------------------------------
  // Audio Asset Playback & Synthesis Fallback
  // ---------------------------------------------------------------------------

  void _precomputeSounds() {
    _purrWav = _generatePurrWav();
    _meowWav = _generateMeowWav();
    _chirpWav = _generateChirpWav();
    _curiousMewWav = _generateCuriousMewWav();
    _chimeWav = _generateBellChimeWav();
    _swatWav = _generateAngrySwatWav();
    _waterWav = _generateWaterDropWav();
    _clickWav = _generateClickWav();
  }

  Future<void> _playAssetOrWav(String assetName, Uint8List wavBytes) async {
    try {
      await _audioPlayer.setVolume(volume);
      // Play local audio MP3 asset through iPhone physical speaker
      await _audioPlayer.play(AssetSource('audio/$assetName.mp3'));
    } catch (_) {
      await _playWav(wavBytes);
    }
  }

  Future<void> _playWav(Uint8List wavBytes) async {
    try {
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play(BytesSource(wavBytes));
    } catch (e) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Generates a soft rhythmic cat purr with low frequency modulation (28 Hz - 45 Hz)
  Uint8List _generatePurrWav() {
    const sampleRate = 22050;
    const durationSec = 0.85;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Amplitude rumble envelope at ~26 Hz (purr cycle)
      final purrRumble = 0.5 + 0.5 * math.sin(2 * math.pi * 26.0 * t);
      // Low base tone with warm harmonics
      final carrier = 0.55 * math.sin(2 * math.pi * 38.0 * t) +
          0.30 * math.sin(2 * math.pi * 76.0 * t) +
          0.15 * math.sin(2 * math.pi * 114.0 * t);
      // Soft fade in/out
      final envelope = math.sin(math.pi * (i / numSamples));
      final sampleVal = (carrier * purrRumble * envelope * 24000).toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Generates a cute cat meow with upward then downward pitch glide and feline vocal formant
  Uint8List _generateMeowWav() {
    const sampleRate = 22050;
    const durationSec = 0.46;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final progress = i / numSamples;
      final t = i / sampleRate;

      // Frequency trajectory: 600 Hz -> 880 Hz peak -> 640 Hz
      final freq = 600.0 + 280.0 * math.sin(math.pi * progress);
      // Feline vocal tract natural micro-vibrato (5.5 Hz)
      final vibrato = 10.0 * math.sin(2 * math.pi * 5.5 * t);
      phase += 2 * math.pi * (freq + vibrato) / sampleRate;

      // Soft vocal formant with 2nd, 3rd, and 4th harmonics
      final wave = 0.60 * math.sin(phase) +
          0.25 * math.sin(2 * phase) +
          0.10 * math.sin(3 * phase) +
          0.05 * math.sin(4 * phase);

      // Smooth attack and release envelope
      double env;
      if (progress < 0.12) {
        env = progress / 0.12;
      } else {
        env = math.exp(-3.2 * (progress - 0.12));
      }

      final sampleVal = (wave * env * 26000).toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Generates a friendly cat chirp / "mrrp" with a pleasant upward trill
  Uint8List _generateChirpWav() {
    const sampleRate = 22050;
    const durationSec = 0.28;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final progress = i / numSamples;
      final t = i / sampleRate;

      // Rapid trill modulation at 25 Hz characteristic of cat chirrup / mrrp
      final trillMod = 1.0 + 0.08 * math.sin(2 * math.pi * 25.0 * t);
      // Pitch glide: 480 Hz -> 840 Hz
      final freq = (480.0 + 360.0 * math.sqrt(progress)) * trillMod;
      phase += 2 * math.pi * freq / sampleRate;

      // Warm feline harmonics
      final wave = 0.65 * math.sin(phase) +
          0.25 * math.sin(2 * phase) +
          0.10 * math.sin(3 * phase);

      // Envelope: fast rise, pleasant trill decay
      final env = math.sin(math.pi * progress) * math.exp(-1.5 * progress);
      final sampleVal = (wave * env * 27000).toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Generates a soft curious kitten questioning "mew?" with upward pitch inflection
  Uint8List _generateCuriousMewWav() {
    const sampleRate = 22050;
    const durationSec = 0.32;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final progress = i / numSamples;
      final t = i / sampleRate;

      // Questioning inflection: 720 Hz rising smoothly to 1100 Hz at end
      final freq = 720.0 + 380.0 * (progress * progress);
      // Subtle sweet vibrato (6 Hz)
      final vibrato = 12.0 * math.sin(2 * math.pi * 6.0 * t);
      phase += 2 * math.pi * (freq + vibrato) / sampleRate;

      final wave = 0.70 * math.sin(phase) +
          0.20 * math.sin(2 * phase) +
          0.10 * math.sin(3 * phase);

      // Envelope: soft attack, gentle lift at the tail
      final env = math.sin(math.pi * progress);
      final sampleVal = (wave * env * 25000).toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Generates a pleasant bell chime combined with a celebratory meow
  Uint8List _generateBellChimeWav() {
    const sampleRate = 22050;
    const durationSec = 1.1;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    double meowPhase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // 1. Resonant bell harmonics (880 Hz, 1760 Hz, 2640 Hz) with exponential decay
      final bellDecay = math.exp(-3.8 * t);
      final bell = (0.50 * math.sin(2 * math.pi * 880.0 * t) +
              0.32 * math.sin(2 * math.pi * 1760.0 * t) +
              0.18 * math.sin(2 * math.pi * 2640.0 * t)) *
          bellDecay;

      // 2. Chirp meow after initial chime impact (starts at 0.15s)
      double meow = 0.0;
      if (t > 0.15 && t < 0.70) {
        final mt = (t - 0.15) / 0.55;
        final mFreq = 740.0 + 220.0 * math.sin(math.pi * mt);
        meowPhase += 2 * math.pi * mFreq / sampleRate;
        final mEnv = math.sin(math.pi * mt);
        meow = (0.6 * math.sin(meowPhase) + 0.4 * math.sin(2 * meowPhase)) *
            mEnv *
            0.55;
      }

      final combined = (bell * 0.7 + meow * 0.3);
      final sampleVal = (combined * 28000).toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Generates a snappy angry swat sound (sharp swipe + hiss + descending pitch)
  Uint8List _generateAngrySwatWav() {
    const sampleRate = 22050;
    const durationSec = 0.32;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);
    final rng = math.Random(42);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final progress = i / numSamples;
      // Sharp descending pitch: 950 Hz -> 260 Hz
      final freq = 950.0 - 690.0 * progress;
      phase += 2 * math.pi * freq / sampleRate;

      // Tone + noise burst for swipe impact
      final tone = math.sin(phase);
      final noise = (rng.nextDouble() * 2.0 - 1.0) * (1.0 - progress);
      final swipe = (0.6 * tone + 0.4 * noise);

      final env = math.exp(-5.0 * progress);
      final sampleVal = (swipe * env * 29000).toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Generates a pleasant water drop sound
  Uint8List _generateWaterDropWav() {
    const sampleRate = 22050;
    const durationSec = 0.28;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final progress = i / numSamples;
      // Upward pitch swoop characteristic of a droplet: 1100 Hz -> 2200 Hz
      final freq = 1100.0 + 1100.0 * (progress * progress);
      phase += 2 * math.pi * freq / sampleRate;

      final env = math.sin(math.pi * progress) * math.exp(-4.0 * progress);
      final sampleVal = (math.sin(phase) * env * 27000).toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Generates a light UI click
  Uint8List _generateClickWav() {
    const sampleRate = 22050;
    const durationSec = 0.035;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final progress = i / numSamples;
      final freq = 1800.0 - 800.0 * progress;
      final env = 1.0 - progress;
      final sampleVal =
          (math.sin(2 * math.pi * freq * (i / sampleRate)) * env * 18000)
              .toInt();
      pcm[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Builds a complete 44-byte RIFF/WAVE header + 16-bit PCM payload
  Uint8List _buildWav(Int16List pcmSamples, int sampleRate) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = pcmSamples.length * 2;
    final fileSize = 36 + dataSize;

    final bytes = ByteData(44 + dataSize);

    // RIFF chunk descriptor
    bytes.setUint8(0, 0x52); // 'R'
    bytes.setUint8(1, 0x49); // 'I'
    bytes.setUint8(2, 0x46); // 'F'
    bytes.setUint8(3, 0x46); // 'F'
    bytes.setUint32(4, fileSize, Endian.little);
    bytes.setUint8(8, 0x57);  // 'W'
    bytes.setUint8(9, 0x41);  // 'A'
    bytes.setUint8(10, 0x56); // 'V'
    bytes.setUint8(11, 0x45); // 'E'

    // 'fmt ' sub-chunk
    bytes.setUint8(12, 0x66); // 'f'
    bytes.setUint8(13, 0x6D); // 'm'
    bytes.setUint8(14, 0x74); // 't'
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    bytes.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    bytes.setUint16(22, numChannels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, byteRate, Endian.little);
    bytes.setUint16(32, blockAlign, Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);

    // 'data' sub-chunk
    bytes.setUint8(36, 0x64); // 'd'
    bytes.setUint8(37, 0x61); // 'a'
    bytes.setUint8(38, 0x74); // 't'
    bytes.setUint8(39, 0x61); // 'a'
    bytes.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < pcmSamples.length; i++) {
      bytes.setInt16(44 + (i * 2), pcmSamples[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }
}
