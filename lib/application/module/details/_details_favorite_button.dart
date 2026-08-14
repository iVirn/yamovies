part of 'movie_details_screen.dart';

class _DetailsFavoriteButton extends StatelessWidget {
  const _DetailsFavoriteButton();

  @override
  Widget build(BuildContext context) {
    final MovieDetailsViewModel viewModel =
        ViewModelScope.of<MovieDetailsViewModel>(context, listen: false);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, Widget? child) {
        final bool isFavorite = viewModel.isFavorite;

        return FilledButton.icon(
          onPressed: viewModel.toggleFavorite,
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          label: Text(
            isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        );
      },
    );
  }
}
