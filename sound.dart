import 'package:audioplayers/audioplayers.dart';

class Sound {
  static final AudioPlayer _player = AudioPlayer();
  static bool soundOn = true;

  static Future<void> playTap() async {
    if (!soundOn) return;
    await _player.stop();
    await _player.play(AssetSource('tap.mp3'));
  }

  static void setSound(bool value) {
    soundOn = value;
  }
}