import 'package:flutter/material.dart';

import 'movie.dart';

class MovieFiltersHeader extends StatelessWidget {
  const MovieFiltersHeader({
    required this.moviesCount,
    required this.selectedGenres,
    required this.onOpenFilters,
    required this.onClearFilters,
    required this.onRemoveGenre,
    super.key,
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
                    Text(
                      '$moviesCount movies found',
                      style: textTheme.bodyMedium,
                    ),
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
            SelectedGenresChips(
              genres: selectedGenres,
              onDeleted: onRemoveGenre,
            ),
          ],
        ],
      ),
    );
  }
}

class SelectedGenresChips extends StatelessWidget {
  const SelectedGenresChips({
    required this.genres,
    required this.onDeleted,
    super.key,
  });

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

class GenreFilterSheet extends StatelessWidget {
  const GenreFilterSheet({
    required this.genres,
    required this.selectedGenreIds,
    required this.onGenreTap,
    required this.onClear,
    super.key,
  });

  final List<Genre> genres;
  final Set<int> selectedGenreIds;
  final ValueChanged<int> onGenreTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Filter by genre',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: selectedGenreIds.isEmpty ? null : onClear,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    for (final Genre genre in genres)
                      CheckboxListTile(
                        value: selectedGenreIds.contains(genre.id),
                        title: Text(genre.name),
                        onChanged: (_) => onGenreTap(genre.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoviesEmptyState extends StatelessWidget {
  const MoviesEmptyState({required this.onClearFilters, super.key});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No movies match these filters',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Clear selected genres to return to the full list.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}
