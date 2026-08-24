// ignore_for_file: avoid_print

import 'package:movie_network/movie_network.dart';
import 'package:yamovies/dependency_injection/service_locator/service_locator.dart';

import '../../data/movie_repository.dart';
import '../../data/tmdb_api.dart';
import '../../data/tmdb_auth_service.dart';
import '../../data/tmdb_config.dart';

void main() {
  const TmdbAuthService authService = TmdbAuthService();
  final NetworkEventBus eventBus = NetworkEventBus();
  final TokenStorage tokenStorage = InMemoryTokenStorage(
    initialToken: TmdbConfig.apiKey,
  );

  locator.register<TokenStorage>(tokenStorage);
  locator.register<NetworkEventBus>(eventBus);
  locator.register<TokenRefresher>(
    TokenRefresher(
      storage: tokenStorage,
      fetchFreshToken: authService.issueAccessToken,
      eventBus: eventBus,
    ),
  );
  locator.register<HttpClient>(
    HttpClient.create(
      HttpClientType.network,
      config: const HttpClientConfig(baseUrl: TmdbConfig.baseUrl),
      tokenStorage: locator.get<TokenStorage>(),
      tokenRefresher: locator.get<TokenRefresher>(),
      eventBus: locator.get<NetworkEventBus>(),
    ),
  );
  locator.register<TmdbApi>(TmdbApi(httpClient: locator.get<HttpClient>()));
  locator.register<MovieRepository>(
    MovieRepositoryImpl(api: locator.get<TmdbApi>()),
  );

  final MovieRepository repository = locator.get<MovieRepository>();

  print('Достали репозиторий: $repository');
}
