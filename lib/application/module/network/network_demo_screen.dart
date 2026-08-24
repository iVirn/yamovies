import 'package:flutter/material.dart';
import 'package:movie_network/movie_network.dart';

import '../../../data/movie_repository.dart';
import '../../../data/tmdb_config.dart';
import '../../../dependency_injection/dependency_container/dependency_container.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../utils/error_messages.dart';

part '_network_event_list.dart';

/// Демо «401 и refresh»: портим токен и смотрим, как цепочка интерсепторов
/// чинит запрос за спиной у экрана.
class NetworkDemoScreen extends StatefulWidget {
  const NetworkDemoScreen({super.key});

  @override
  State<NetworkDemoScreen> createState() => _NetworkDemoScreenState();
}

class _NetworkDemoScreenState extends State<NetworkDemoScreen> {
  late final DependencyContainer _container;
  String _lastResult = 'Ничего ещё не запрашивали';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _container = DependencyScope.of(context);
  }

  Future<void> _breakToken() async {
    await _container.tokenStorage.writeAccessToken('expired-token-0000');
    setState(() => _lastResult = 'Токен подменён на просроченный');
  }

  Future<void> _restoreToken() async {
    await _container.tokenStorage.writeAccessToken(TmdbConfig.apiKey);
    setState(() => _lastResult = 'Токен восстановлен');
  }

  Future<void> _loadFeed() async {
    setState(() => _isBusy = true);

    try {
      final int count = (await _container.movieRepository.getMovies())
          .results
          .length;
      setState(() => _lastResult = 'Лента приехала: $count фильмов');
    } catch (error) {
      setState(() => _lastResult = describeLoadError(error));
    } finally {
      setState(() => _isBusy = false);
    }
  }

  /// Пять запросов разом — то самое «стадо 401».
  Future<void> _loadFiveAtOnce() async {
    setState(() => _isBusy = true);

    final MovieRepository repository = _container.movieRepository;
    final int refreshesBefore = _container.tokenRefresher.refreshCallsSent;

    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      repository.getMovies().then<Object?>((Object? value) => value),
      repository.getGenres().then<Object?>((Object? value) => value),
      repository.getMovieDetails(278).then<Object?>((Object? value) => value),
      repository.getMovieCast(278).then<Object?>((Object? value) => value),
      repository.getSimilarMovies(278).then<Object?>((Object? value) => value),
    ], eagerError: false).catchError((Object error) => <Object?>[]);

    final int refreshes =
        _container.tokenRefresher.refreshCallsSent - refreshesBefore;

    setState(() {
      _isBusy = false;
      _lastResult =
          'Пять запросов завершились (${results.length} ответов), '
          'refresh ушёл $refreshes раз';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TokenRefresher refresher = _container.tokenRefresher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network: 401 → refresh'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Clear log',
            onPressed: () => setState(_container.networkEventBus.clear),
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!TmdbConfig.hasApiKey)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Демо работает только с ключом TMDB: запустите приложение '
                'с --dart-define=TMDB_API_KEY=<ключ>.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: _isBusy ? null : _breakToken,
                  child: const Text('Break token'),
                ),
                FilledButton.tonal(
                  onPressed: _isBusy ? null : _restoreToken,
                  child: const Text('Restore token'),
                ),
                FilledButton(
                  onPressed: _isBusy ? null : _loadFeed,
                  child: const Text('Load feed'),
                ),
                FilledButton(
                  onPressed: _isBusy ? null : _loadFiveAtOnce,
                  child: const Text('5 requests at once'),
                ),
              ],
            ),
          ),
          SwitchListTile.adaptive(
            value: refresher.useQueue,
            onChanged: (bool value) =>
                setState(() => refresher.useQueue = value),
            title: const Text('Queue refresh requests'),
            subtitle: Text(
              refresher.useQueue
                  ? 'Первый 401 обновляет токен, остальные ждут его Future'
                  : 'Каждый 401 обновляет токен сам — сервер увидит стадо',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_lastResult · refresh за сессию: ${refresher.refreshCallsSent}',
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (_isBusy) const LinearProgressIndicator(),
          const Divider(),
          Expanded(child: _NetworkEventList(eventBus: _container.networkEventBus)),
        ],
      ),
    );
  }
}
