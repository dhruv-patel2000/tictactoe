import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:tic_tac_toe/utils/local_storage.dart';

/// Static facade over background music and one-shot sound effects (click,
/// win jingle), with a session token so only the screen that last started
/// music can stop it.
abstract class SoundService {
  static const String _musicAsset = 'music/music.mp3';
  static const String _clickAsset = 'music/click.mp3';
  static const String _winAsset = 'music/wingame.mp3';

  static const double _musicVolume = 1;

  /// Volume the background music drops to while the win jingle plays, instead
  /// of pausing it. Ducking is recoverable even if the jingle's completion
  /// event never arrives; a pause that is only undone from a callback is not.
  static const double _duckedMusicVolume = 0.2;

  /// Safety net for [_playOneShot]: if a completion event is ever dropped, the
  /// ducked music volume would stay down for the rest of the session. Clips
  /// here are a few seconds long, so this only ever fires on a lost event.
  static const Duration _oneShotTimeout = Duration(seconds: 10);

  static AudioPlayer?
      _musicPlayer; // lazily-created, single looping player for background music

  /// One long-lived player per sound effect. Effects are short and replaying
  /// one restarts it, so a player per clip is enough and — unlike a fresh
  /// player per play — cannot leak native players.
  static final Map<String, AudioPlayer> _sfxPlayers = <String, AudioPlayer>{};

  static bool _enabled =
      true; // user's mute preference, persisted via LocalStorage

  /// Whether the current screen wants background music playing at all, as
  /// opposed to [_enabled] which is the user's mute preference. Kept separate
  /// so that muting mid-game and un-muting mid-game both work regardless of
  /// whether music happened to be enabled when the game screen was entered.
  static bool _wantsMusic = false;

  /// Identifies which screen currently "owns" background music. On restart,
  /// Navigator.pushReplacementNamed builds the new MazeScreen (which calls
  /// playBackgroundMusic) before the old one's dispose (stopBackgroundMusic)
  /// runs, since removal happens after the route transition. Without this
  /// guard the old screen's stale stopBackgroundMusic call would kill the
  /// music the new screen just started.
  static Object? _activeSession;

  static Future<void>?
      _initFuture; // memoizes _init() so init() only runs once per app session

  static bool get isEnabled => _enabled;

  static Future<void> init() => _initFuture ??= _init();

  static Future<void> _init() async {
    _enabled = LocalStorage.isSoundEnabled();
    if (kDebugMode) {
      AudioLogger.logLevel = AudioLogLevel.info;
    }
    try {
      // Set once, before any player exists, so every player inherits it on
      // creation. Setting a context per player instead makes the plugin
      // rewrite global AudioManager / AVAudioSession state and tear down and
      // rebuild the native player on each play, which is what made playback
      // unreliable.
      //
      // No audio focus (Android) / mixWithOthers (iOS) so that starting a
      // sound effect never takes focus away from the music player and pauses
      // it. `playback` on iOS also keeps audio audible with the ringer switch
      // set to silent, which is what a game is expected to do.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const <AVAudioSessionOptions>{
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (e) {
      _log('could not set the global audio context', e);
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await LocalStorage.setSoundEnabled(enabled);
    if (enabled) {
      await _startOrResumeMusic();
    } else {
      try {
        await _musicPlayer?.pause();
      } catch (e) {
        _log('could not pause background music', e);
      }
    }
  }

  static Future<void> playBackgroundMusic(Object session) async {
    _activeSession = session;
    _wantsMusic = true;
    await _startOrResumeMusic();
  }

  static Future<void> stopBackgroundMusic(Object session) async {
    // A newer screen has already taken over background music; this call is
    // from a screen that's only now getting around to disposing.
    if (_activeSession != session) return;
    _activeSession = null;
    _wantsMusic = false;
    try {
      await _musicPlayer?.stop();
    } catch (e) {
      _log('could not stop background music', e);
    }
  }

  static Future<void> playClick() => _playOneShot(_clickAsset);

  static Future<void> playWin() async {
    if (!_enabled) return;
    await _setMusicVolume(_duckedMusicVolume);
    await _playOneShot(
      _winAsset,
      onComplete: () => _setMusicVolume(_musicVolume),
    );
  }

  static Future<void> _startOrResumeMusic() async {
    if (!_wantsMusic || !_enabled) return;
    try {
      final AudioPlayer player = await _music();
      // The owning screen may have been disposed, or the user may have muted,
      // while the player was being created.
      if (!_wantsMusic || !_enabled) return;
      if (player.state == PlayerState.playing) return;
      await player.setVolume(_musicVolume);
      if (player.state == PlayerState.paused) {
        await player.resume();
      } else {
        await player.play(AssetSource(_musicAsset));
      }
    } catch (e) {
      _log('could not start background music', e);
    }
  }

  static Future<void> _setMusicVolume(double volume) async {
    try {
      await _musicPlayer?.setVolume(volume);
    } catch (e) {
      _log('could not change the background music volume', e);
    }
  }

  static Future<AudioPlayer> _music() async {
    final AudioPlayer? existing = _musicPlayer;
    if (existing != null) return existing;
    final AudioPlayer player = AudioPlayer(playerId: 'background-music');
    _musicPlayer = player;
    await player.setReleaseMode(ReleaseMode.loop);
    return player;
  }

  static Future<AudioPlayer> _sfxPlayer(String assetPath) async {
    final AudioPlayer? existing = _sfxPlayers[assetPath];
    if (existing != null) return existing;
    // The player id ends up inside a platform channel name on iOS, so keep it
    // free of the asset path's separators and dots.
    final String id = assetPath.replaceAll(RegExp(r'[^A-Za-z0-9]'), '-');
    final AudioPlayer player = AudioPlayer(playerId: 'sfx-$id');
    _sfxPlayers[assetPath] = player;
    // Keep the prepared source around between plays, but rewind on finish so
    // the next play starts from the top.
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  /// Plays a short sound effect. [onComplete] runs once the clip finishes, or
  /// after [_oneShotTimeout] if the platform never reports completion, so a
  /// caller waiting on it can never be left hanging.
  static Future<void> _playOneShot(
    String assetPath, {
    Future<void> Function()? onComplete,
  }) async {
    if (!_enabled) return;

    StreamSubscription<void>? completeSub;
    Timer? timeout;
    bool finished =
        false; // guards finish() so it only runs once, whichever trigger fires first
    Future<void> finish() async {
      if (finished) return;
      finished = true;
      timeout?.cancel();
      await completeSub?.cancel();
      await onComplete?.call();
    }

    try {
      final AudioPlayer player = await _sfxPlayer(assetPath);
      if (onComplete != null) {
        completeSub = player.onPlayerComplete.listen((_) {
          finish();
        });
        timeout = Timer(_oneShotTimeout, finish);
      }
      // Rewind if this clip is still playing from a previous, rapid tap.
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (e) {
      _log('could not play $assetPath', e);
      await finish();
    }
  }

  static void _log(String message, Object error) {
    if (kDebugMode) {
      debugPrint('SoundService: $message ($error)');
    }
  }
}
