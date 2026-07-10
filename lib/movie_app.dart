import 'package:flutter/material.dart';

import 'features/movies/movie_list_screen.dart';

/// The YaMovies application root.
///
/// Pass [assetPackage] when YaMovies is consumed as a package by another
/// Flutter application. Standalone applications should leave it `null`.
class MovieApp extends StatelessWidget {
  const MovieApp({this.assetPackage, super.key});

  final String? assetPackage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YaMovies',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MovieListScreen(assetPackage: assetPackage),
    );
  }
}
