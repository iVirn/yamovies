part of 'movie_details_screen.dart';

/// Второй из трёх запросов экрана: `/movie/{id}/credits`.
class _CastRow extends StatelessWidget {
  const _CastRow({required this.cast});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final List<CastMember> visibleCast = cast.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text('Cast', style: theme.textTheme.titleLarge),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: visibleCast.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final CastMember member = visibleCast[index];

              return SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 108,
                        width: 96,
                        child: _CastPhoto(member: member),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      member.character,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CastPhoto extends StatelessWidget {
  const _CastPhoto({required this.member});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    final String? url = TmdbConfig.posterUrl(member.profilePath, size: 'w185');
    if (url == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.person_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      // Декодируем под ячейку: 96 логических пикселей на 3x-экране.
      cacheWidth: 288,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              const PosterFallback(),
    );
  }
}
