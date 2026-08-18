import 'package:flutter/material.dart';

import '../../../domain/movie.dart';

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
