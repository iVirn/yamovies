// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movie_network/movie_network.dart';
import 'package:rxdart/rxdart.dart';

import '../../../data/movie_repository.dart';
import '../../../domain/movie.dart';
import '../../../utils/error_messages.dart';
import '../../controller.dart';

/// Как строка поиска ходит в сеть.
enum SearchMode {
  /// ❌ Запрос на каждую букву, ответы приходят вперемешку.
  everyKeystroke,

  /// ⚠️ Пауза 300 мс — запросов меньше, но гонка ответов осталась.
  debounce,

  /// ✅ Пауза плюс отмена незавершённого запроса: на экране всегда ответ
  /// на последний ввод.
  debounceAndSwitchMap,
}

/// Состояние выдачи.
sealed class MovieSearchState {
  const MovieSearchState();
}

final class SearchIdleState extends MovieSearchState {
  const SearchIdleState();
}

final class SearchLoadingState extends MovieSearchState {
  const SearchLoadingState({required this.query});

  final String query;
}

final class SearchResultsState extends MovieSearchState {
  const SearchResultsState({required this.query, required this.movies});

  final String query;
  final List<Movie> movies;
}

final class SearchFailureState extends MovieSearchState {
  const SearchFailureState({required this.query, required this.message});

  final String query;
  final String message;
}

enum SearchRequestStatus { inFlight, done, cancelled, failed }

/// Строка журнала запросов — тот самый Network-таб, только на экране.
class SearchRequestEntry {
  SearchRequestEntry({required this.query, required this.startedAt});

  final String query;
  final DateTime startedAt;
  SearchRequestStatus status = SearchRequestStatus.inFlight;
  Duration? duration;
}

class MovieSearchController extends Controller {
  MovieSearchController({required MovieRepository repository})
    : _repository = repository {
    _rebuildPipeline();
  }

  final MovieRepository _repository;

  /// `BehaviorSubject` — контроллер, который отдаёт новому подписчику
  /// последнее значение. Ради него обычно и берут rxdart.
  final BehaviorSubject<String> _query = BehaviorSubject<String>.seeded('');
  final BehaviorSubject<MovieSearchState> _state =
      BehaviorSubject<MovieSearchState>.seeded(const SearchIdleState());

  final List<SearchRequestEntry> _log = <SearchRequestEntry>[];

  StreamSubscription<MovieSearchState>? _pipeline;
  SearchMode _mode = SearchMode.everyKeystroke;
  bool _isDisposed = false;

  Stream<MovieSearchState> get state => _state.stream;

  MovieSearchState get currentState => _state.value;

  List<SearchRequestEntry> get log =>
      List<SearchRequestEntry>.unmodifiable(_log);

  SearchMode get mode => _mode;

  int get inFlightCount => _log
      .where((SearchRequestEntry e) => e.status == SearchRequestStatus.inFlight)
      .length;

  void onQueryChanged(String query) {
    if (_isDisposed) {
      return;
    }

    _query.add(query);
  }

  /// Уведомлять слушателей после `dispose` нельзя: `ChangeNotifier` за это
  /// бросает исключение. А колбэки запроса живут дольше экрана — отмена
  /// подписки приходит уже после того, как контроллер закрыт.
  void _notifyIfAlive() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  void setMode(SearchMode mode) {
    if (_mode == mode) {
      return;
    }

    _mode = mode;
    _log.clear();
    _state.add(const SearchIdleState());
    _rebuildPipeline();
    notifyListeners();
  }

  void clearLog() {
    _log.clear();
    notifyListeners();
  }

  /// Сборка конвейера. Общая часть одинакова для всех режимов, различие —
  /// в двух операторах: `debounceTime` и `switchMap` против `asyncExpand`.
  void _rebuildPipeline() {
    _pipeline?.cancel();

    final Stream<String> queries = _query.stream
        .map((String query) => query.trim())
        .where((String query) => query.length >= 2)
        .distinct();

    final Stream<String> debounced = _mode == SearchMode.everyKeystroke
        ? queries
        : queries.debounceTime(const Duration(milliseconds: 300));

    final Stream<MovieSearchState> results = switch (_mode) {
      // asyncExpand ничего не отменяет: гонка ответов остаётся, просто реже.
      SearchMode.everyKeystroke ||
      SearchMode.debounce => debounced.asyncExpand(_search),
      // switchMap отменяет предыдущий внутренний поток — вместе с запросом.
      SearchMode.debounceAndSwitchMap => debounced.switchMap(_search),
    };

    _pipeline = results.listen(
      _state.add,
      onError: (Object error, StackTrace stackTrace) =>
          debugPrint('[search] поток упал: $error'),
    );
  }

  /// Один запрос как поток.
  ///
  /// `Stream.multi` даёт то, ради чего всё затевалось: колбэк `onCancel`.
  /// Когда `switchMap` отписывается от предыдущего запроса, мы дёргаем
  /// `CancelToken` — и запрос действительно обрывается, а не просто
  /// перестаёт быть нужным.
  ///
  /// Поток обязан завершиться: `switchMap` подписывается на новый запрос
  /// только после того, как закончился предыдущий. Незакрытый поток молча
  /// вешает всю строку поиска — выдача замирает на первом запросе.
  Stream<MovieSearchState> _search(String query) {
    return Stream<MovieSearchState>.multi((
      MultiStreamController<MovieSearchState> controller,
    ) async {
      final CancelToken cancelToken = CancelToken();
      final SearchRequestEntry entry = SearchRequestEntry(
        query: query,
        startedAt: DateTime.now(),
      );
      final Stopwatch stopwatch = Stopwatch()..start();

      controller.onCancel = () {
        if (entry.status != SearchRequestStatus.inFlight) {
          return;
        }

        entry
          ..status = SearchRequestStatus.cancelled
          ..duration = stopwatch.elapsed;
        cancelToken.cancel('строка поиска: приехал новый ввод');
        _notifyIfAlive();
      };

      _log.insert(0, entry);
      _notifyIfAlive();
      controller.add(SearchLoadingState(query: query));

      try {
        final List<Movie> movies = await _repository.searchMovies(
          query,
          cancelToken: cancelToken,
        );

        if (!cancelToken.isCancelled) {
          entry
            ..status = SearchRequestStatus.done
            ..duration = stopwatch.elapsed;
          _notifyIfAlive();
          controller.add(SearchResultsState(query: query, movies: movies));
        }
      } catch (error) {
        if (!cancelToken.isCancelled) {
          entry
            ..status = SearchRequestStatus.failed
            ..duration = stopwatch.elapsed;
          _notifyIfAlive();
          controller.add(
            SearchFailureState(query: query, message: describeLoadError(error)),
          );
        }
      } finally {
        controller.close();
      }
    });
  }

  @override
  void dispose() {
    // Порядок важен: сначала помечаем себя закрытым и снимаем подписку
    // на конвейер, и только потом закрываем subject-ы. Иначе последнее
    // событие придёт в уже закрытый контроллер.
    _isDisposed = true;
    unawaited(_pipeline?.cancel());
    _pipeline = null;
    unawaited(_query.close());
    unawaited(_state.close());
    super.dispose();
  }
}
