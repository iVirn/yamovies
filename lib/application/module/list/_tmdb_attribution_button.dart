part of 'movie_list_screen.dart';

class _TmdbAttributionButton extends StatelessWidget {
  const _TmdbAttributionButton();

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
