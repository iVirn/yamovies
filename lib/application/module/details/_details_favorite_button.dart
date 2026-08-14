part of 'movie_details_screen.dart';

class _DetailsFavoriteButton extends StatelessWidget {
  const _DetailsFavoriteButton();

  @override
  Widget build(BuildContext context) {
    final MovieDetailsController controller =
        ControllerScope.of<MovieDetailsController>(context, listen: false);

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final bool isFavorite = controller.isFavorite;

        return FilledButton.icon(
          onPressed: controller.toggleFavorite,
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          label: Text(
            isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        );
      },
    );
  }
}
