import 'package:flutter/material.dart';
import 'package:yamovies/application/module/list/movie_list_screen.dart';

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YaMovies',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
        useMaterial3: true,
      ),
      home: const MovieListScreen(),
    );
  }
}
