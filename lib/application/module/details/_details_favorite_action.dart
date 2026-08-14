part of 'movie_details_screen.dart';

class _DetailsFavoriteAction extends StatelessWidget {
  const _DetailsFavoriteAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
      builder: (BuildContext context, MovieDetailsState state) {
        final bool isFavorite = switch (state) {
          MovieDetailsFavoriteState() => true,
          MovieDetailsNotFavoriteState() => false,
        };

        return IconButton.filledTonal(
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: () => context.read<MovieDetailsBloc>().add(
            const MovieDetailsFavoriteToggled(),
          ),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.redAccent : null,
          ),
        );
      },
    );
  }
}
