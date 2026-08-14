import 'package:flutter/material.dart';

class PosterFallback extends StatelessWidget {
  const PosterFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
