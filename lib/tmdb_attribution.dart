import 'package:flutter/material.dart';

const String tmdbAttributionNotice =
    'This product uses the TMDB API but is not endorsed or certified by TMDB.';

class TmdbAttributionButton extends StatelessWidget {
  const TmdbAttributionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      tooltip: 'About and credits',
      onPressed: () {
        showAboutDialog(
          context: context,
          applicationName: 'YaMovies',
          applicationIcon: Image.asset(
            'assets/branding/tmdb-logo.png',
            width: 64,
            height: 64,
          ),
          children: const <Widget>[Text(tmdbAttributionNotice)],
        );
      },
    );
  }
}
