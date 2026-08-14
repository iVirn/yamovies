// ignore_for_file: avoid_print

import 'package:yamovies/dependency_injection/service_locator/service_locator.dart';

import '../../data/database.dart';
import '../../data/http_client.dart';
import '../../data/movie_repository.dart';

void main() {
  locator.register<HttpClient>(const NetworkHttpClient());
  locator.register<Database>(const SqliteDatabase());
  locator.register<MovieRepository>(
    MovieRepositoryImpl(
      httpClient: locator.get<HttpClient>(),
      database: locator.get<Database>(),
    ),
  );

  final MovieRepository repository = locator.get<MovieRepository>();

  print('Достали репозиторий: $repository');
}
