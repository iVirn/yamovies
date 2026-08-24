part of 'movie_list_screen.dart';

/// Демо «режим полёта»: очередь изменений и то, что с ней происходит.
class _OutboxPanel extends StatelessWidget {
  const _OutboxPanel();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DependencyContainer container = DependencyScope.of(context);
    final DemoSettings demoSettings = container.demoSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.cloud_upload_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Outbox', style: theme.textTheme.titleMedium),
            ),
            TextButton(
              onPressed: container.syncService.kick,
              child: const Text('Sync now'),
            ),
          ],
        ),
        ListenableBuilder(
          listenable: demoSettings,
          builder: (BuildContext context, Widget? child) {
            return Column(
              children: <Widget>[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: demoSettings.airplaneMode,
                  onChanged: (bool value) => demoSettings.airplaneMode = value,
                  title: const Text('Airplane mode'),
                  subtitle: Text(
                    demoSettings.airplaneMode
                        ? 'Сеть выключена: лента живёт на кэше, очередь копится'
                        : 'Сеть есть: очередь уходит на сервер',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: demoSettings.simulateConflict,
                  onChanged: (bool value) =>
                      demoSettings.simulateConflict = value,
                  title: const Text('Server answers 409'),
                  subtitle: Text(
                    'Для фильмов с чётным id сервер говорит «уже не в избранном»',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<SyncStatus>(
          stream: container.syncService.status,
          builder: (BuildContext context, AsyncSnapshot<SyncStatus> snapshot) {
            final SyncStatus? status = snapshot.data;
            if (status == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'В очереди: ${status.pendingCount} · '
                'dead letter: ${status.deadCount}'
                '${status.lastMessage == null ? '' : ' · ${status.lastMessage}'}',
                style: theme.textTheme.bodySmall,
              ),
            );
          },
        ),
        StreamBuilder<List<OutboxEntry>>(
          stream: container.syncService.queue,
          initialData: const <OutboxEntry>[],
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<OutboxEntry>> snapshot,
              ) {
                final List<OutboxEntry> ops =
                    snapshot.data ?? const <OutboxEntry>[];

                if (ops.isEmpty) {
                  return Text(
                    'Очередь пуста — всё уехало на сервер.',
                    style: theme.textTheme.bodySmall,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final OutboxEntry op in ops.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '#${op.id} ${op.kind} movie ${op.movieId} · '
                          '${op.status} · попыток ${op.attempts} · '
                          'idem ${op.idempotencyKey}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              },
        ),
      ],
    );
  }
}
