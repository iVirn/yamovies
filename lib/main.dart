import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movie_network/movie_network.dart';
import 'package:yamovies/application/demo_settings.dart';
import 'package:yamovies/application/movie_app.dart';
import 'package:yamovies/data/favorites_service.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/data/tmdb_api.dart';
import 'package:yamovies/data/tmdb_config.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_container.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_owner.dart';

void main() {
  // runZonedGuarded нужен один раз в main: без него ошибка future, которого
  // никто не ждал, уходит в никуда и крашлитика её не увидит.
  runZonedGuarded<void>(
    () {
      final DependencyContainer container = DependencyContainer(
        movieRepository: _createRepository(),
        favoritesService: FavoritesService(),
        demoSettings: DemoSettings(),
      );

      runApp(DependencyOwner(container: container, child: const MovieApp()));
    },
    (Object error, StackTrace stackTrace) =>
        debugPrint('Unhandled error: $error\n$stackTrace'),
  );
}

/// Есть ключ — идём в TMDB, нет — работаем на офлайн-фикстуре.
///
/// Ключ передаётся сборкой:
/// `flutter run --dart-define=TMDB_API_KEY=...`
MovieRepository _createRepository() {
  if (!TmdbConfig.hasApiKey) {
    debugPrint(
      'TMDB_API_KEY не передан: работаем на офлайн-фикстуре. '
      'Запустите с --dart-define=TMDB_API_KEY=<ключ>, чтобы увидеть сеть.',
    );

    return const MovieRepositoryMock();
  }

  // Один клиент на приложение: пул соединений, keep-alive и — дальше
  // по курсу — общие интерсепторы.
  final HttpClient httpClient = HttpClient.create(
    HttpClientType.network,
    config: const HttpClientConfig(
      baseUrl: TmdbConfig.baseUrl,
      apiKey: TmdbConfig.apiKey,
    ),
  );

  return MovieRepositoryImpl(api: TmdbApi(httpClient: httpClient));
}
