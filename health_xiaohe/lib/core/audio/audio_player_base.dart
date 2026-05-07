import 'dart:async';

abstract class AudioPlayerBase {
  Future<void> play(String base64Pcm);
  void stop();
  void dispose();
}
