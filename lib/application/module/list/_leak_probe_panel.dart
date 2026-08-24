part of 'movie_list_screen.dart';

/// Демо «утечка подписки» с ленты: сколько подписок пережило свои экраны.
///
/// Заходим на экран фильма и возвращаемся несколько раз, потом переключаем
/// избранное — и видно, скольким мёртвым экранам ушло событие.
class _LeakProbePanel extends StatelessWidget {
  const _LeakProbePanel();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DemoSettings demoSettings = DependencyScope.of(context).demoSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.memory, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Subscriptions', style: theme.textTheme.titleMedium),
            ),
            IconButton(
              tooltip: 'Reset counters',
              onPressed: LeakProbe.reset,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: LeakProbe.liveSubscriptions,
                builder: (BuildContext context, int value, Widget? child) {
                  return _LeakStat(label: 'Live listeners', value: value);
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: LeakProbe.zombieCallbacks,
                builder: (BuildContext context, int value, Widget? child) {
                  return _LeakStat(
                    label: 'Calls after dispose',
                    value: value,
                    isAlarming: value > 0,
                  );
                },
              ),
            ),
          ],
        ),
        ListenableBuilder(
          listenable: demoSettings,
          builder: (BuildContext context, Widget? child) {
            return SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: demoSettings.cancelSubscriptionOnDispose,
              onChanged: (bool value) =>
                  demoSettings.cancelSubscriptionOnDispose = value,
              title: const Text('cancel() in dispose'),
              subtitle: Text(
                demoSettings.cancelSubscriptionOnDispose
                    ? 'Movie screen releases its listener on the way out'
                    : 'Movie screen leaves the listener alive',
                style: theme.textTheme.bodySmall,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LeakStat extends StatelessWidget {
  const _LeakStat({
    required this.label,
    required this.value,
    this.isAlarming = false,
  });

  final String label;
  final int value;
  final bool isAlarming;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: isAlarming ? theme.colorScheme.error : null,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
