part of 'movie_details_screen.dart';

/// Пульт демо «три запроса разом»: переключили — нажали «перезагрузить»
/// в шапке экрана — сравнили секундомер.
class _DetailsDemoPanel extends StatelessWidget {
  const _DetailsDemoPanel({required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DemoSettings demoSettings = DependencyScope.of(context).demoSettings;

    return ListenableBuilder(
      listenable: demoSettings,
      builder: (BuildContext context, Widget? child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Demo: how the screen loads',
              style: theme.textTheme.titleSmall,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: demoSettings.parallelDetailsLoad,
              onChanged: (bool value) =>
                  demoSettings.parallelDetailsLoad = value,
              title: const Text('Future.wait instead of three awaits'),
              subtitle: Text(
                demoSettings.parallelDetailsLoad
                    ? 'Three requests start together'
                    : 'Every request waits for the previous one',
                style: theme.textTheme.bodySmall,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: demoSettings.breakCastRequest,
              onChanged: (bool value) => demoSettings.breakCastRequest = value,
              title: const Text('Break the cast request'),
              subtitle: Text(
                'Asks TMDB for a movie that does not exist',
                style: theme.textTheme.bodySmall,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: demoSettings.eagerErrorOnDetails,
              onChanged: demoSettings.parallelDetailsLoad
                  ? (bool value) => demoSettings.eagerErrorOnDetails = value
                  : null,
              title: const Text('eagerError: true'),
              subtitle: Text(
                demoSettings.eagerErrorOnDetails
                    ? 'Fail as soon as one request fails'
                    : 'Wait for all three, then show what arrived',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Text('Deep link', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(
              'adb shell am start -a android.intent.action.VIEW '
              '-d "yamovies://movie/$movieId/cast"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Перезагрузка экрана теми же настройками — чтобы не выходить и не заходить.
class _DetailsReloadAction extends StatelessWidget {
  const _DetailsReloadAction();

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'Reload with current demo settings',
      onPressed: () =>
          context.read<MovieDetailsBloc>().add(const MovieDetailsReloaded()),
      icon: const Icon(Icons.refresh),
    );
  }
}
