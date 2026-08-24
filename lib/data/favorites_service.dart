import 'dart:async';

import 'package:flutter/foundation.dart';

/// Избранное как источник, который живёт дольше одного ответа.
///
/// Вопрос-ответ — это `Future`. А здесь значения приходят снова и снова, пока
/// жив экран: добавили фильм на ленте — перерисовалась и лента, и карточка
/// фильма. Такое отдают `Stream`.
///
/// Контроллер — `broadcast`: слушателей несколько (лента, счётчик в шапке,
/// экран фильма). Плата за это — выпущенное до подписки теряется, поэтому
/// текущее состояние всегда доступно синхронно через [current], а виджеты
/// отдают его `StreamBuilder`-у как `initialData`.
class FavoritesService {
  FavoritesService() {
    _controller = StreamController<Set<int>>.broadcast(
      onListen: () => debugPrint('[favorites] появился первый слушатель'),
      onCancel: () => debugPrint('[favorites] слушателей не осталось'),
    );
  }

  late final StreamController<Set<int>> _controller;
  final Set<int> _favoriteMovieIds = <int>{};

  /// Текущее состояние — синхронно и без подписки.
  Set<int> get current => Set<int>.unmodifiable(_favoriteMovieIds);

  /// Поток изменений: новое множество на каждое переключение.
  Stream<Set<int>> get changes => _controller.stream;

  /// Поток «этот фильм в избранном» — то, что нужно карточке фильма.
  Stream<bool> watchIsFavorite(int movieId) =>
      changes.map((Set<int> ids) => ids.contains(movieId)).distinct();

  bool isFavorite(int movieId) => _favoriteMovieIds.contains(movieId);

  void toggle(int movieId) {
    if (!_favoriteMovieIds.add(movieId)) {
      _favoriteMovieIds.remove(movieId);
    }

    // Новое значение каждый раз новым множеством: подписчик не должен
    // получить ссылку на изменяемое состояние сервиса.
    _controller.add(current);
  }

  /// Владелец сервиса закрывает контроллер: после `close()` вызов `add()`
  /// бросит исключение, а подписчики получат `onDone`.
  Future<void> dispose() => _controller.close();
}
