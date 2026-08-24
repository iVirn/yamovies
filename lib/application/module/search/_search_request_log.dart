part of 'movie_search_screen.dart';

/// Журнал запросов: сколько их ушло, сколько отменено, сколько ещё в полёте.
class _SearchRequestLog extends StatelessWidget {
  const _SearchRequestLog();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MovieSearchController controller =
        ControllerScope.of<MovieSearchController>(context, listen: false);

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final List<SearchRequestEntry> entries = controller.log;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Requests: ${entries.length} · '
                      'in flight: ${controller.inFlightCount}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: controller.clearLog,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              SizedBox(
                height: 84,
                child: entries.isEmpty
                    ? Text(
                        'No requests yet.',
                        style: theme.textTheme.bodySmall,
                      )
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _SearchRequestTile(entry: entries[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchRequestTile extends StatelessWidget {
  const _SearchRequestTile({required this.entry});

  final SearchRequestEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (IconData icon, Color color, String label) = switch (entry.status) {
      SearchRequestStatus.inFlight => (
        Icons.hourglass_top,
        theme.colorScheme.primary,
        'in flight',
      ),
      SearchRequestStatus.done => (
        Icons.check_circle_outline,
        Colors.green,
        'done in ${entry.duration?.inMilliseconds ?? 0} ms',
      ),
      SearchRequestStatus.cancelled => (
        Icons.cancel_outlined,
        theme.colorScheme.tertiary,
        'cancelled after ${entry.duration?.inMilliseconds ?? 0} ms',
      ),
      SearchRequestStatus.failed => (
        Icons.error_outline,
        theme.colorScheme.error,
        'failed',
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '«${entry.query}» — $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
