// ignore_for_file: avoid_print

import 'package:movie_network/movie_network.dart';
import 'package:yamovies/dependency_injection/service_locator/service_locator.dart';

import '../../data/movie_repository.dart';
import '../../data/tmdb_api.dart';
import '../../data/tmdb_config.dart';

void main() {
  locator.register<HttpClient>(
    HttpClient.create(
      HttpClientType.network,
      config: const HttpClientConfig(
        baseUrl: TmdbConfig.baseUrl,
        apiKey: TmdbConfig.apiKey,
      ),
    ),
  );
  locator.register<TmdbApi>(TmdbApi(httpClient: locator.get<HttpClient>()));
  locator.register<MovieRepository>(
    MovieRepositoryImpl(api: locator.get<TmdbApi>()),
  );

  final MovieRepository repository = locator.get<MovieRepository>();

  print('Достали репозиторий: $repository');
}
