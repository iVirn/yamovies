part of 'movie_details_screen.dart';

class _MovieDetailsView extends StatelessWidget {
  const _MovieDetailsView({required this.genreNames});

  final List<String> genreNames;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
      buildWhen: (MovieDetailsState previous, MovieDetailsState current) =>
          previous is! MovieDetailsLoadingState ||
          current is! MovieDetailsLoadingState,
      builder: (BuildContext context, MovieDetailsState state) {
        return switch (state) {
          MovieDetailsLoadingState() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          MovieDetailsSuccessState(:final Movie movie) => _MovieDetailsContent(
            movie: movie,
            genreNames: genreNames,
          ),
        };
      },
    );
  }
}
