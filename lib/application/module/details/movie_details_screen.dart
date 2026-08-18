import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/poster_fallback.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_formatters.dart';
import '../../../utils/movie_poster_assets.dart';
import '../../controller_scope.dart';
import 'bloc/movie_details_bloc.dart';
import 'movie_details_controller.dart';

part '_details_favorite_action.dart';
part '_details_favorite_button.dart';
part '_details_poster.dart';
part '_expandable_overview.dart';
part '_meta_pill.dart';
part '_movie_details_content.dart';
part '_movie_details_view.dart';
part '_overview_text.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({
    required this.movieId,
    required this.genreNames,
    required this.isFavorite,
    required this.onFavoriteTap,
    super.key,
  });

  final int movieId;
  final List<String> genreNames;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late final MovieDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MovieDetailsController(
      isFavorite: widget.isFavorite,
      onFavoriteTap: widget.onFavoriteTap,
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
        movieId: widget.movieId,
      )..add(const MovieDetailsStarted()),
      child: ControllerScope<MovieDetailsController>(
        controller: _controller,
        child: _MovieDetailsView(genreNames: widget.genreNames),
      ),
    );
  }
}
