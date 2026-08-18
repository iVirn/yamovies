part of 'movie_list_screen.dart';

class _MovieFiltersHeader extends StatelessWidget {
  const _MovieFiltersHeader({
    required this.moviesCount,
    required this.selectedGenres,
    required this.onOpenFilters,
    required this.onClearFilters,
    required this.onRemoveGenre,
  });

  final int moviesCount;
  final List<Genre> selectedGenres;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;
  final ValueChanged<int> onRemoveGenre;

  bool get _hasSelectedGenres => selectedGenres.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Browse movies', style: textTheme.headlineSmall),
                    Text('$moviesCount movies found', style: textTheme.bodyMedium),
                  ],
                ),
              ),
              if (_hasSelectedGenres)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear'),
                ),
              FilledButton.icon(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune),
                label: const Text('Filters'),
              ),
            ],
          ),
          if (_hasSelectedGenres) ...<Widget>[
            const SizedBox(height: 12),
            _SelectedGenresChips(genres: selectedGenres, onDeleted: onRemoveGenre),
          ],
        ],
      ),
    );
  }
}
