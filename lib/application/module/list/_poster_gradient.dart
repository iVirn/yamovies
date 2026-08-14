part of 'movie_list_screen.dart';

class _PosterGradient extends StatelessWidget {
  const _PosterGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
      ),
    );
  }
}
