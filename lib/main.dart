import 'package:flutter/material.dart';

import 'tmdb_attribution.dart';

void main() {
  runApp(const MovieApp());
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YaMovies',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Top Rated Movies'),
          actions: const <Widget>[TmdbAttributionButton()],
        ),
        body: const Center(child: Text('Hello Flutter')),
      ),
    );
  }
}
