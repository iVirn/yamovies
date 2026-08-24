import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../components/movie_poster.dart';
import '../../../components/poster_fallback.dart';
import '../../../data/tmdb_config.dart';
import '../../../dependency_injection/dependency_container/dependency_container.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/movie.dart';
import '../../../domain/movie_details.dart';
import '../../../utils/movie_formatters.dart';
import '../../controller_scope.dart';
import '../../router/app_router.dart';
import '../../leak_probe.dart';
import '../../demo_settings.dart';
import 'bloc/movie_details_bloc.dart';
import 'movie_details_controller.dart';

part '_cast_row.dart';
part '_details_demo_panel.dart';
part '_details_favorite_action.dart';
part '_details_favorite_button.dart';
part '_details_load_timing.dart';
part '_details_poster.dart';
part '_favorite_activity_log.dart';
part '_expandable_overview.dart';
part '_meta_pill.dart';
part '_movie_details_content.dart';
part '_movie_details_view.dart';
part '_overview_text.dart';
part '_similar_movies_row.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({
    required this.movieId,
    this.genreNames = const <String>[],
    super.key,
  });

  final int movieId;

  /// Жанры, известные ленте. По диплинку их нет — тогда экран покажет те,
  /// что приедут вместе с деталями.
  final List<String> genreNames;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late final MovieDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MovieDetailsController(
      favoritesService: DependencyScope.of(context).favoritesService,
      movieId: widget.movieId,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MovieDetailsBloc>(
      create: (BuildContext context) => MovieDetailsBloc(
        repository: DependencyScope.of(context).movieRepository,
        demoSettings: DependencyScope.of(context).demoSettings,
        movieId: widget.movieId,
      )..add(const MovieDetailsStarted()),
      child: ControllerScope<MovieDetailsController>(
        controller: _controller,
        child: _MovieDetailsView(
          genreNames: widget.genreNames,
          movieId: widget.movieId,
        ),
      ),
    );
  }
}
