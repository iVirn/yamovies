part of 'movie_search_screen.dart';

class _SearchModeSelector extends StatelessWidget {
  const _SearchModeSelector();

  @override
  Widget build(BuildContext context) {
    final MovieSearchController controller =
        ControllerScope.of<MovieSearchController>(context, listen: false);

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<SearchMode>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<SearchMode>>[
              ButtonSegment<SearchMode>(
                value: SearchMode.everyKeystroke,
                label: Text('raw'),
                tooltip: 'Request on every keystroke',
              ),
              ButtonSegment<SearchMode>(
                value: SearchMode.debounce,
                label: Text('debounce'),
                tooltip: 'debounceTime(300ms) + asyncExpand',
              ),
              ButtonSegment<SearchMode>(
                value: SearchMode.debounceAndSwitchMap,
                label: Text('switchMap'),
                tooltip: 'debounceTime(300ms) + switchMap',
              ),
            ],
            selected: <SearchMode>{controller.mode},
            onSelectionChanged: (Set<SearchMode> selection) =>
                controller.setMode(selection.first),
          ),
        );
      },
    );
  }
}
