part of 'movie_search_screen.dart';

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final MovieSearchController controller =
        ControllerScope.of<MovieSearchController>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          labelText: 'Movie title',
          helperText: 'Type at least two characters',
        ),
        // Каждый символ уходит в поток; что с ним делать дальше — решают
        // операторы, а не виджет.
        onChanged: controller.onQueryChanged,
      ),
    );
  }
}
