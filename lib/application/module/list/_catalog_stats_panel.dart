part of 'movie_list_screen.dart';

/// Демо «UI замирает».
///
/// Панель держит на экране два живых индикатора: бесконечный
/// `LinearProgressIndicator` и вращающуюся иконку. Оба рисуются кадр за кадром,
/// поэтому любая блокировка UI-изолята видна сразу — картинка встаёт.
class _CatalogStatsPanel extends StatelessWidget {
  const _CatalogStatsPanel({required this.movies, required this.controller});

  final List<Movie> movies;
  final MovieListController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DemoSettings demoSettings = DependencyScope.of(context).demoSettings;
    final CatalogStatsRun? run = controller.statsRun;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const _FrameHeartbeat(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Catalogue index',
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Recalculate',
              onPressed: controller.isComputingStats
                  ? null
                  : () => controller.recalculateStats(movies),
              icon: const Icon(Icons.calculate_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: demoSettings,
          builder: (BuildContext context, Widget? child) {
            return SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: demoSettings.computeStatsInIsolate,
              onChanged: (bool value) =>
                  demoSettings.computeStatsInIsolate = value,
              title: const Text('Compute in a separate isolate'),
              subtitle: Text(
                demoSettings.computeStatsInIsolate
                    ? 'Isolate.run: UI keeps drawing frames'
                    : 'UI isolate: frames and taps are blocked',
                style: theme.textTheme.bodySmall,
              ),
            );
          },
        ),
        if (run != null) ...<Widget>[
          const Divider(height: 24),
          _CatalogStatsResult(run: run),
        ],
      ],
    );
  }
}

class _CatalogStatsResult extends StatelessWidget {
  const _CatalogStatsResult({required this.run});

  final CatalogStatsRun run;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CatalogStats stats = run.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${run.duration.inMilliseconds} ms '
          '${run.inIsolate ? 'in Isolate.run' : 'on the UI isolate'}',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Average rating ${stats.averageRating.toStringAsFixed(2)} · '
          'top keyword "${stats.topKeyword}" (${stats.topKeywordHits}) · '
          '${stats.wordsProcessed} words processed',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Пульс кадров: пока UI-изолят свободен, иконка вращается равномерно.
class _FrameHeartbeat extends StatefulWidget {
  const _FrameHeartbeat();

  @override
  State<_FrameHeartbeat> createState() => _FrameHeartbeatState();
}

class _FrameHeartbeatState extends State<_FrameHeartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animationController,
      child: Icon(
        Icons.autorenew,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
