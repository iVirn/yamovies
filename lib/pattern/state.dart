// ignore_for_file: avoid_print

abstract interface class PlayerState {
  void play(MediaPlayer player);
  void pause(MediaPlayer player);
  void stop(MediaPlayer player);
}

abstract interface class PlayerStateListener {
  void onStateChanged(PlayerState previous, PlayerState current);
}

class MediaPlayer {
  MediaPlayer() : _state = const StoppedState();

  PlayerState _state;
  final _listeners = <PlayerStateListener>[];

  void addStateListener(PlayerStateListener listener) {
    _listeners.add(listener);
  }

  void setState(PlayerState state) {
    final previousState = _state;
    _state = state;

    for (final listener in _listeners) {
      listener.onStateChanged(previousState, state);
    }
  }

  void play() => _state.play(this);
  void pause() => _state.pause(this);
  void stop() => _state.stop(this);
}

class PlayerStateLogger implements PlayerStateListener {
  const PlayerStateLogger();

  @override
  void onStateChanged(PlayerState previous, PlayerState current) {
    print('Подписчик: ${previous.runtimeType} -> ${current.runtimeType}');
  }
}

class StoppedState implements PlayerState {
  const StoppedState();

  @override
  void play(MediaPlayer player) {
    print('Запускаю воспроизведение');
    player.setState(const PlayingState());
  }

  @override
  void pause(MediaPlayer player) {
    print('Нельзя поставить на паузу: плеер остановлен');
  }

  @override
  void stop(MediaPlayer player) {
    print('Плеер уже остановлен');
  }
}

class PlayingState implements PlayerState {
  const PlayingState();

  @override
  void play(MediaPlayer player) {
    print('Уже воспроизводится');
  }

  @override
  void pause(MediaPlayer player) {
    print('Ставлю на паузу');
    player.setState(const PausedState());
  }

  @override
  void stop(MediaPlayer player) {
    print('Останавливаю воспроизведение');
    player.setState(const StoppedState());
  }
}

class PausedState implements PlayerState {
  const PausedState();

  @override
  void play(MediaPlayer player) {
    print('Продолжаю воспроизведение');
    player.setState(const PlayingState());
  }

  @override
  void pause(MediaPlayer player) {
    print('Уже на паузе');
  }

  @override
  void stop(MediaPlayer player) {
    print('Останавливаю воспроизведение');
    player.setState(const StoppedState());
  }
}

void main() {
  final player = MediaPlayer();
  player.addStateListener(const PlayerStateLogger());

  player.play();
  player.pause();
  player.play();
  player.stop();
  player.pause();
}
