import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around [AudioPlayer] for one-shot SFX.
///
/// Two pools of players are pre-created so overlapping sounds don't
/// cut each other (e.g. fast answer taps).  Each pool has 4 slots that
/// cycle round-robin.
class SoundService {
  SoundService() {
    // Pre-create player pools
    _answerPool = List.generate(4, (_) => AudioPlayer());
    _clickPool  = List.generate(4, (_) => AudioPlayer());
    for (final p in [..._answerPool, ..._clickPool]) {
      p.setReleaseMode(ReleaseMode.stop);
    }
  }

  late final List<AudioPlayer> _answerPool;
  late final List<AudioPlayer> _clickPool;
  int _answerIdx = 0;
  int _clickIdx  = 0;

  static const _answerAsset = 'sounds/buttonAnswer.mp3';
  static const _clickAsset  = 'sounds/buttonClick.mp3';

  /// Play the answer-tap sound (quiz option button).
  Future<void> playAnswer() async {
    final player = _answerPool[_answerIdx % _answerPool.length];
    _answerIdx++;
    await player.stop();
    await player.play(AssetSource(_answerAsset), volume: 0.7);
  }

  /// Play the shell-button click sound (nav buttons, PixelButton).
  Future<void> playClick() async {
    final player = _clickPool[_clickIdx % _clickPool.length];
    _clickIdx++;
    await player.stop();
    await player.play(AssetSource(_clickAsset), volume: 0.6);
  }

  void dispose() {
    for (final p in [..._answerPool, ..._clickPool]) {
      p.dispose();
    }
  }
}

/// Global singleton — lives for the app lifetime.
final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  ref.onDispose(svc.dispose);
  return svc;
});
