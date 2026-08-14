part of 'movie_list_screen.dart';

class _SelectedGenresChips extends StatelessWidget {
  const _SelectedGenresChips({required this.genres, required this.onDeleted});

  final List<Genre> genres;
  final ValueChanged<int> onDeleted;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final Genre genre in genres)
          Chip(label: Text(genre.name), onDeleted: () => onDeleted(genre.id)),
      ],
    );
  }
}
