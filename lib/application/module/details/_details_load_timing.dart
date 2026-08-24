part of 'movie_details_screen.dart';

/// Секундомер экрана: тот самый лог из демо «три запроса разом», но на виду.
class _DetailsLoadTiming extends StatelessWidget {
  const _DetailsLoadTiming({required this.bundle});

  final MovieDetailsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final double seconds = bundle.loadDuration.inMilliseconds / 1000;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  bundle.loadedInParallel ? Icons.call_split : Icons.linear_scale,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bundle.loadedInParallel
                        ? '3 requests via Future.wait · ${seconds.toStringAsFixed(2)} s'
                        : '3 requests one after another · ${seconds.toStringAsFixed(2)} s',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bundle.loadedInParallel
                  ? 'Screen time is the slowest request, not the sum of three.'
                  : 'Screen time is the sum of all three waits.',
              style: theme.textTheme.bodySmall,
            ),
            for (final String error in bundle.partialErrors) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
