part of 'movie_list_screen.dart';

/// Все лекционные переключатели ленты в одном месте.
///
/// Свёрнута по умолчанию: демо не должно занимать экран, пока его не показывают.
class _DemoPanelSection extends StatelessWidget {
  const _DemoPanelSection({required this.movies, required this.controller});

  final List<Movie> movies;
  final MovieListController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: const Icon(Icons.science_outlined),
          title: const Text('Lecture demos'),
          subtitle: const Text('Isolate, subscriptions, outbox'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _CatalogStatsPanel(movies: movies, controller: controller),
            const Divider(height: 32),
            const _LeakProbePanel(),
            const Divider(height: 32),
            const _OutboxPanel(),
          ],
        ),
      ),
    );
  }
}
