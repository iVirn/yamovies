import 'package:flutter/material.dart';
// import 'package:yamovies/data/database.dart';
// import 'package:yamovies/data/http_client.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_container.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_scope.dart';
import 'package:yamovies/application/movie_app.dart';

void main() {
  // final httpClient = NetworkHttpClient();
  // final database = SqliteDatabase();
  // final movieRepository = MovieRepositoryImpl(
  //   httpClient: httpClient,
  //   database: database,
  // );
  final movieRepository = const MovieRepositoryMock();

  final container = DependencyContainer(movieRepository: movieRepository);

  runApp(DependencyScope(container: container, child: const MovieApp()));
}
