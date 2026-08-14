part of 'movie_details_screen.dart';

class _OverviewText extends StatelessWidget {
  const _OverviewText({required this.text, required this.isExpanded});

  final String text;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final Text textWidget = Text(
      text,
      maxLines: isExpanded ? null : 4,
      overflow: TextOverflow.visible,
      style: Theme.of(context).textTheme.bodyLarge,
    );

    if (isExpanded) {
      return textWidget;
    }

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: <double>[0, 0.72, 1],
          colors: <Color>[Colors.white, Colors.white, Colors.transparent],
        ).createShader(bounds);
      },
      child: textWidget,
    );
  }
}
