import 'package:flutter/material.dart';

class ExpandableOverview extends StatefulWidget {
  const ExpandableOverview({required this.text, super.key});

  final String text;

  @override
  State<ExpandableOverview> createState() => _ExpandableOverviewState();
}

class _ExpandableOverviewState extends State<ExpandableOverview> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfaceContainerLow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _OverviewText(text: widget.text, isExpanded: _isExpanded),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _toggleExpanded,
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  label: Text(_isExpanded ? 'Show less' : 'Read more'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
