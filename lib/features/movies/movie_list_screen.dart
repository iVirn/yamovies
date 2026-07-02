import 'package:flutter/material.dart';

import '../../tmdb_attribution.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Movies'),
        actions: const <Widget>[TmdbAttributionButton()],
      ),
      body: const Center(child: Text('Hello Flutter')),
    );
  }
}
