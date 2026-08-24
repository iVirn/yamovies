part of 'movie_list_screen.dart';

/// Второй подписчик того же потока — поэтому контроллер и сделан `broadcast`.
///
/// `initialData` обязателен: broadcast-поток не хранит последнее значение,
/// и без него счётчик мигнёт пустотой до первого события.
class _FavoritesCounter extends StatelessWidget {
  const _FavoritesCounter();

  @override
  Widget build(BuildContext context) {
    final FavoritesService favorites =
        DependencyScope.of(context).favoritesService;

    return StreamBuilder<Set<int>>(
      stream: favorites.changes,
      initialData: favorites.current,
      builder: (BuildContext context, AsyncSnapshot<Set<int>> snapshot) {
        final int count = snapshot.data?.length ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Chip(
            avatar: const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
            label: Text('$count'),
            visualDensity: VisualDensity.compact,
          ),
        );
      },
    );
  }
}
