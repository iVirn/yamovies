part of 'network_demo_screen.dart';

/// Лог цепочки интерсепторов: запрос, ошибка, refresh, повтор, ответ.
class _NetworkEventList extends StatelessWidget {
  const _NetworkEventList({required this.eventBus});

  final NetworkEventBus eventBus;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkEvent>(
      stream: eventBus.events,
      builder: (BuildContext context, AsyncSnapshot<NetworkEvent> snapshot) {
        final List<NetworkEvent> events = eventBus.history;

        if (events.isEmpty) {
          return const Center(child: Text('Лог пуст'));
        }

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (BuildContext context, int index) {
            final NetworkEvent event = events[index];
            final (IconData icon, Color color) = _decorationFor(
              context,
              event.kind,
            );

            return ListTile(
              dense: true,
              leading: Icon(icon, color: color),
              title: Text(event.message),
              subtitle: Text(
                <String>[
                  if (event.statusCode != null) 'HTTP ${event.statusCode}',
                  if (event.duration != null)
                    '${event.duration!.inMilliseconds} ms',
                  _formatTime(event.at),
                ].join(' · '),
              ),
            );
          },
        );
      },
    );
  }

  (IconData, Color) _decorationFor(BuildContext context, NetworkEventKind kind) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return switch (kind) {
      NetworkEventKind.request => (Icons.north_east, colors.primary),
      NetworkEventKind.response => (Icons.south_west, Colors.green),
      NetworkEventKind.failure => (Icons.error_outline, colors.error),
      NetworkEventKind.refreshStarted => (Icons.vpn_key_outlined, colors.tertiary),
      NetworkEventKind.refreshDone => (Icons.vpn_key, colors.tertiary),
      NetworkEventKind.retry => (Icons.replay, colors.secondary),
    };
  }

  String _formatTime(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}:'
      '${at.second.toString().padLeft(2, '0')}.'
      '${at.millisecond.toString().padLeft(3, '0')}';
}
