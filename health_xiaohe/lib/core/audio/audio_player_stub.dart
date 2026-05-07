// Native 平台音频播放 — 暂未实现
import 'audio_player_base.dart';

class AudioPlayer extends AudioPlayerBase {
  @override
  Future<void> play(String base64Pcm) async {}

  @override
  void stop() {}

  @override
  void dispose() {}
}
