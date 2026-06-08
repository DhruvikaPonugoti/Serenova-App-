import 'package:audioplayers/audioplayers.dart';

class Music {
  static final AudioPlayer _player = AudioPlayer();
  static bool musicOn = true;   // 👈 track switch state

 static Future<void> play() async {
  if (!musicOn) return;

  if (_player.state == PlayerState.playing) return;

  await _player.setReleaseMode(ReleaseMode.loop);
  await _player.play(AssetSource("bg_music.mp3"));
}

  static Future<void> stop() async {
    await _player.stop();
  }

  static void setMusic(bool value) {
    musicOn = value;
    if (value) {
      play();
    } else {
      stop();
    }
  }
}
