part of 'movie_details_screen.dart';

class _DetailsFavoriteAction extends StatelessWidget {
  const _DetailsFavoriteAction();

  @override
  Widget build(BuildContext context) {
    final MovieDetailsViewModel viewModel =
        ViewModelScope.of<MovieDetailsViewModel>(context, listen: false);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, Widget? child) {
        final bool isFavorite = viewModel.isFavorite;

        return IconButton.filledTonal(
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: viewModel.toggleFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.redAccent : null,
          ),
        );
      },
    );
  }
}
