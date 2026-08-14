// ignore_for_file: avoid_print

import 'package:movie_database/movie_database.dart';
import 'package:movie_network/movie_network.dart';
import 'package:yamovies/dependency_injection/service_locator/service_locator.dart';

import '../../data/movie_repository.dart';

void main() {
  locator.register<HttpClient>(HttpClient.create(HttpClientType.network));
  locator.register<Database>(Database.create(DatabaseType.sqlite));
  locator.register<MovieRepository>(
    MovieRepositoryImpl(
      httpClient: locator.get<HttpClient>(),
      database: locator.get<Database>(),
    ),
  );

  final MovieRepository repository = locator.get<MovieRepository>();

  print('Достали репозиторий: $repository');
}
