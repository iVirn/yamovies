import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/movie_poster.dart';

import '../../../data/favorites_service.dart';
import '../../../data/movie_repository.dart';
import '../../../data/sync_service.dart';
import '../../../dependency_injection/dependency_container/dependency_container.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/catalog_stats.dart';
import '../../../domain/movie.dart';
import '../../../utils/error_messages.dart';
import '../../../utils/movie_filters.dart';
import '../../../utils/movie_formatters.dart';
import '../../../utils/tmdb_attribution.dart';
import '../../controller_scope.dart';
import '../../leak_probe.dart';
import '../../demo_settings.dart';
import '../cache/cache_inspector_screen.dart';
import '../network/network_demo_screen.dart';
import '../search/movie_search_screen.dart';
import '../storage/token_storage_screen.dart';
import 'bloc/movie_list_bloc.dart';
import 'movie_list_controller.dart';

part '_catalog_stats_panel.dart';
part '_demo_panel_section.dart';
part '_favorites_counter.dart';
part '_leak_probe_panel.dart';
part '_outbox_panel.dart';
part '_movie_card.dart';
part '_movie_filters_header.dart';
part '_movie_list_content.dart';
part '_movie_list_view.dart';
part '_movies_empty_state.dart';
part '_poster_gradient.dart';
part '_rating_badge.dart';
part '_selected_genres_chips.dart';
part '_tmdb_attribution_button.dart';
part '_top_movie_poster.dart';
part '_top_movie_tile.dart';
part '_top_movies_gallery.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final MovieListController _controller;

  @override
  void initState() {
    super.initState();
    final DependencyContainer container = DependencyScope.of(context);
    _controller = MovieListController(
      demoSettings: container.demoSettings,
      favoritesService: container.favoritesService,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MovieListBloc>(
      create: (BuildContext context) =>
          MovieListBloc(repository: DependencyScope.of(context).movieRepository)
            ..add(const MovieListStarted()),
      child: ControllerScope<MovieListController>(
        controller: _controller,
        child: const _MovieListView(),
      ),
    );
  }
}
