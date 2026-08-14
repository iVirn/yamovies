part of 'movie_details_screen.dart';

class _DetailsFavoriteButton extends StatelessWidget {
  const _DetailsFavoriteButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
      builder: (BuildContext context, MovieDetailsState state) {
        final bool isFavorite = switch (state) {
          MovieDetailsFavoriteState() => true,
          MovieDetailsNotFavoriteState() => false,
        };

        return FilledButton.icon(
          onPressed: () => context.read<MovieDetailsBloc>().add(
            const MovieDetailsFavoriteToggled(),
          ),
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          label: Text(
            isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        );
      },
    );
  }
}
