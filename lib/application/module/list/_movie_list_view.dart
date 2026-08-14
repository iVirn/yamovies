part of 'movie_list_screen.dart';

class _MovieListView extends StatelessWidget {
  const _MovieListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Movies'),
        actions: const <Widget>[_TmdbAttributionButton()],
      ),
      body: BlocBuilder<MovieListBloc, MovieListState>(
        buildWhen: (MovieListState previous, MovieListState current) =>
            previous is! MovieListLoadingState ||
            current is! MovieListLoadingState,
        builder: (BuildContext context, MovieListState state) {
          return switch (state) {
            MovieListLoadingState() => const Center(
              child: CircularProgressIndicator(),
            ),
            MovieListSuccessState() => _MovieListContent(state: state),
          };
        },
      ),
    );
  }
}
