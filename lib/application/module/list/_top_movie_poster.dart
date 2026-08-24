part of 'movie_list_screen.dart';

class _TopMoviePoster extends StatelessWidget {
  const _TopMoviePoster({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return MoviePoster(
      movieId: movie.id,
      posterPath: movie.posterPath,
      title: movie.title,
      size: 'w185',
      cacheWidth: 288,
    );
  }
}
