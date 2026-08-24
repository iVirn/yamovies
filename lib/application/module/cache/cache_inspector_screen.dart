import 'package:flutter/material.dart';

import '../../../data/cached_movie_repository.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/movie.dart';

/// Что лежит в локальной базе прямо сейчас.
///
/// Экран смотрит на кэш через репозиторий: строки таблиц и классы drift
/// остаются в слое данных, наверх приезжают доменные модели.
class CacheInspectorScreen extends StatefulWidget {
  const CacheInspectorScreen({super.key});

  @override
  State<CacheInspectorScreen> createState() => _CacheInspectorScreenState();
}

class _CacheInspectorScreenState extends State<CacheInspectorScreen> {
  /// Поток создаём один раз: созданный в `build`, он пересоздавался бы
  /// на каждую перерисовку — и экран ушёл бы в бесконечный цикл.
  Stream<CacheSnapshot>? _snapshots;
  CachedMovieRepository? _repository;

  @override
  void initState() {
    super.initState();

    final Object repository = DependencyScope.of(context).movieRepository;
    if (repository is CachedMovieRepository) {
      _repository = repository;
      _snapshots = repository.watchCacheSnapshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Stream<CacheSnapshot>? snapshots = _snapshots;

    if (snapshots == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Local cache')),
        body: const Center(child: Text('Этот запуск работает без кэша')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local cache'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Clear cache',
            onPressed: () => _repository?.clearCache(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: StreamBuilder<CacheSnapshot>(
        stream: snapshots,
        builder:
            (BuildContext context, AsyncSnapshot<CacheSnapshot> asyncSnapshot) {
              final CacheSnapshot? snapshot = asyncSnapshot.data;
              final List<Movie> movies = snapshot?.movies ?? const <Movie>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${movies.length} movies in SQLite · '
                      'last sync: ${_formatTime(snapshot?.lastSyncAt)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: movies.isEmpty
                        ? const Center(child: Text('Кэш пуст'))
                        : ListView.builder(
                            itemCount: movies.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Movie movie = movies[index];

                              return ListTile(
                                dense: true,
                                title: Text(movie.title),
                                subtitle: Text(
                                  'id ${movie.id} · ★ '
                                  '${movie.voteAverage.toStringAsFixed(1)} · '
                                  'genres ${movie.genreIds.join(',')}',
                                ),
                                trailing: Text(
                                  _formatTime(snapshot?.cachedAt[movie.id]),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
      ),
    );
  }

  String _formatTime(DateTime? at) {
    if (at == null) {
      return '—';
    }

    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}:'
        '${at.second.toString().padLeft(2, '0')}';
  }
}
