part of 'movie_list_screen.dart';

class _MovieListView extends StatelessWidget {
  const _MovieListView();

  @override
  Widget build(BuildContext context) {
    final MovieListController controller =
        ControllerScope.of<MovieListController>(context, listen: false);

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
            MovieListSuccessState success => ListenableBuilder(
              listenable: controller,
              builder: (BuildContext context, Widget? child) {
                return _MovieListContent(state: success, controller: controller);
              },
            ),
          };
        },
      ),
    );
  }
}
