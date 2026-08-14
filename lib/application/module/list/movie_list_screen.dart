import 'dart:async';

import 'package:flutter/material.dart';

import '../../../components/poster_fallback.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_formatters.dart';
import '../../../utils/movie_poster_assets.dart';
import '../../../utils/tmdb_attribution.dart';
import '../../view_model_scope.dart';
import 'movie_list_view_model.dart';

part '_movie_card.dart';
part '_movie_filters_header.dart';
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
  late final MovieListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final repository = DependencyScope.of(context).movieRepository;
    _viewModel = MovieListViewModel(repository: repository)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<MovieListViewModel>(
      viewModel: _viewModel,
      child: const _MovieListView(),
    );
  }
}
