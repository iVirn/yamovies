part of 'movie_details_screen.dart';

class _DetailsPoster extends StatelessWidget {
  const _DetailsPoster({required this.details});

  final MovieDetails details;

  @override
  Widget build(BuildContext context) {
    return MoviePoster(
      movieId: details.id,
      posterPath: details.posterPath,
      title: details.title,
    );
  }
}
