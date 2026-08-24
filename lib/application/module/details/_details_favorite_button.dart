part of 'movie_details_screen.dart';

class _DetailsFavoriteButton extends StatelessWidget {
  const _DetailsFavoriteButton();

  @override
  Widget build(BuildContext context) {
    final MovieDetailsController controller =
        ControllerScope.of<MovieDetailsController>(context, listen: false);

    return StreamBuilder<bool>(
      stream: controller.isFavoriteChanges,
      initialData: controller.isFavoriteNow,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        final bool isFavorite = snapshot.data ?? false;

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
