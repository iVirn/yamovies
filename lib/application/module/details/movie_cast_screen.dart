import 'package:flutter/material.dart';

import '../../../data/tmdb_config.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/movie_details.dart';
import '../../../utils/error_messages.dart';

/// Экран «Актёры» — тот, что открывает диплинк `yamovies://movie/278/cast`.
///
/// Он живёт вложенным маршрутом, поэтому кнопка «назад» ведёт на экран фильма,
/// а оттуда на ленту — даже если приложение открыли по ссылке с нуля.
class MovieCastScreen extends StatefulWidget {
  const MovieCastScreen({required this.movieId, super.key});

  final int movieId;

  @override
  State<MovieCastScreen> createState() => _MovieCastScreenState();
}

class _MovieCastScreenState extends State<MovieCastScreen> {
  /// Future создаётся один раз, а не в `build`: иначе каждый rebuild уходил бы
  /// новым запросом в сеть.
  late final Future<List<CastMember>> _cast;

  @override
  void initState() {
    super.initState();
    _cast = DependencyScope.of(
      context,
    ).movieRepository.getMovieCast(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cast')),
      body: FutureBuilder<List<CastMember>>(
        future: _cast,
        builder:
            (BuildContext context, AsyncSnapshot<List<CastMember>> snapshot) =>
                switch (snapshot) {
                  AsyncSnapshot<List<CastMember>>(
                    connectionState: ConnectionState.waiting,
                  ) =>
                    const Center(child: CircularProgressIndicator()),
                  AsyncSnapshot<List<CastMember>>(
                    hasError: true,
                    error: final Object error?,
                  ) =>
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          describeLoadError(error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  AsyncSnapshot<List<CastMember>>(
                    data: final List<CastMember> cast?,
                  ) =>
                    _CastList(cast: cast),
                  _ => const SizedBox.shrink(),
                },
      ),
    );
  }
}

class _CastList extends StatelessWidget {
  const _CastList({required this.cast});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const Center(child: Text('TMDB не знает актёров этого фильма'));
    }

    return ListView.builder(
      itemCount: cast.length,
      itemBuilder: (BuildContext context, int index) {
        final CastMember member = cast[index];
        final String? photoUrl = TmdbConfig.posterUrl(
          member.profilePath,
          size: 'w185',
        );

        return ListTile(
          leading: CircleAvatar(
            foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
            child: const Icon(Icons.person_outline),
          ),
          title: Text(member.name),
          subtitle: Text(member.character),
        );
      },
    );
  }
}
