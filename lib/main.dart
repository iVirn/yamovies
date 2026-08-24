import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movie_network/movie_network.dart';
import 'package:yamovies/application/demo_settings.dart';
import 'package:yamovies/application/movie_app.dart';
import 'package:yamovies/data/favorites_service.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/data/tmdb_api.dart';
import 'package:yamovies/data/tmdb_auth_service.dart';
import 'package:yamovies/data/tmdb_config.dart';
import 'package:yamovies/data/token_storages.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_container.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_owner.dart';

void main() {
  // runZonedGuarded нужен один раз в main: без него ошибка future, которого
  // никто не ждал, уходит в никуда и крашлитика её не увидит.
  runZonedGuarded<void>(
    () async {
      // Плагины хранилищ читаются через каналы платформы, поэтому биндинг
      // нужно поднять до первого обращения к ним.
      WidgetsFlutterBinding.ensureInitialized();

      final NetworkEventBus eventBus = NetworkEventBus();
      final DemoSettings demoSettings = DemoSettings();
      final TokenStorage tokenStorage = await _createTokenStorage(demoSettings);
      const TmdbAuthService authService = TmdbAuthService();
      final TokenRefresher tokenRefresher = TokenRefresher(
        storage: tokenStorage,
        fetchFreshToken: authService.issueAccessToken,
        eventBus: eventBus,
      );

      final DependencyContainer container = DependencyContainer(
        movieRepository: _createRepository(
          tokenStorage: tokenStorage,
          tokenRefresher: tokenRefresher,
          eventBus: eventBus,
        ),
        favoritesService: FavoritesService(),
        tokenStorage: tokenStorage,
        tokenRefresher: tokenRefresher,
        networkEventBus: eventBus,
        demoSettings: demoSettings,
      );

      runApp(DependencyOwner(container: container, child: const MovieApp()));
    },
    (Object error, StackTrace stackTrace) =>
        debugPrint('Unhandled error: $error\n$stackTrace'),
  );
}

/// Токен приложения: `flutter_secure_storage` или `SharedPreferences` —
/// переключается на экране демо. Без ключа TMDB прятать нечего, поэтому
/// в офлайн-режиме остаётся хранилище в памяти.
Future<TokenStorage> _createTokenStorage(DemoSettings demoSettings) async {
  if (!TmdbConfig.hasApiKey) {
    return InMemoryTokenStorage();
  }

  final SwitchableTokenStorage storage = SwitchableTokenStorage(
    prefsStorage: PrefsTokenStorage(),
    secureStorage: SecureTokenStorage(),
    demoSettings: demoSettings,
  );

  // Ключ из сборки — это «результат логина»: кладём его в хранилище,
  // дальше сеть берёт токен только оттуда.
  await storage.writeAccessToken(TmdbConfig.apiKey);

  return storage;
}

/// Есть ключ — идём в TMDB, нет — работаем на офлайн-фикстуре.
///
/// Ключ передаётся сборкой:
/// `flutter run --dart-define=TMDB_API_KEY=...`
MovieRepository _createRepository({
  required TokenStorage tokenStorage,
  required TokenRefresher tokenRefresher,
  required NetworkEventBus eventBus,
}) {
  if (!TmdbConfig.hasApiKey) {
    debugPrint(
      'TMDB_API_KEY не передан: работаем на офлайн-фикстуре. '
      'Запустите с --dart-define=TMDB_API_KEY=<ключ>, чтобы увидеть сеть.',
    );

    return const MovieRepositoryMock();
  }

  // Один клиент на приложение: пул соединений, keep-alive и общая цепочка
  // интерсепторов.
  final HttpClient httpClient = HttpClient.create(
    HttpClientType.network,
    config: const HttpClientConfig(baseUrl: TmdbConfig.baseUrl),
    tokenStorage: tokenStorage,
    tokenRefresher: tokenRefresher,
    eventBus: eventBus,
  );

  return MovieRepositoryImpl(api: TmdbApi(httpClient: httpClient));
}
