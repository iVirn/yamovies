part of 'movie_details_screen.dart';

/// Демо «утечка подписки».
///
/// Здесь подписка сделана руками — так, как её делают, когда `StreamBuilder`
/// не годится: событие нужно не только нарисовать, но и записать в журнал.
/// Руками — значит и отменять руками.
class _FavoriteActivityLog extends StatefulWidget {
  const _FavoriteActivityLog();

  @override
  State<_FavoriteActivityLog> createState() => _FavoriteActivityLogState();
}

class _FavoriteActivityLogState extends State<_FavoriteActivityLog> {
  static int _instanceCounter = 0;

  late final int _instanceId;
  late final DemoSettings _demoSettings;
  StreamSubscription<Set<int>>? _subscription;
  final List<String> _events = <String>[];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _instanceId = ++_instanceCounter;

    final DependencyContainer container = DependencyScope.of(context);
    _demoSettings = container.demoSettings;

    _subscription = container.favoritesService.changes.listen(
      _onFavoritesChanged,
      onError: (Object error, StackTrace stackTrace) =>
          debugPrint('[activity #$_instanceId] ошибка потока: $error'),
      onDone: () => debugPrint('[activity #$_instanceId] поток закрыт'),
    );
    LeakProbe.subscriptionOpened();
  }

  @override
  void dispose() {
    _isDisposed = true;

    // ✅ Единственный способ остановить поток — отменить подписку.
    // ❌ Выключенный переключатель оставляет её жить: колбэк держит ссылку
    //    на State, State — на дерево, и всё это не собирается сборщиком.
    if (_demoSettings.cancelSubscriptionOnDispose) {
      _subscription?.cancel();
      LeakProbe.subscriptionClosed();
    } else {
      debugPrint(
        '[activity #$_instanceId] экран закрыт, а подписка осталась жить',
      );
    }

    super.dispose();
  }

  void _onFavoritesChanged(Set<int> favoriteIds) {
    if (_isDisposed) {
      // Подписка пережила экран: setState здесь бросит
      // «setState() called after dispose». Считаем такие вызовы, чтобы
      // утечку было видно без DevTools.
      LeakProbe.zombieCallback();
      debugPrint(
        '[activity #$_instanceId] событие пришло экрану, которого уже нет',
      );
    }

    setState(() {
      _events.insert(0, '${favoriteIds.length} movies in favorites');
      if (_events.length > 5) {
        _events.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Favorite activity (screen #$_instanceId)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_events.isEmpty)
          Text(
            'Toggle a favorite to see events arriving through a manual listen().',
            style: theme.textTheme.bodySmall,
          )
        else
          for (final String event in _events)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Icon(Icons.bolt, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(event, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
      ],
    );
  }
}
