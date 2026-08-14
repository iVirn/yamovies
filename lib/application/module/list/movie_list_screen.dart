import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/poster_fallback.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_filters.dart';
import '../../../utils/movie_formatters.dart';
import '../../../utils/movie_poster_assets.dart';
import '../../../utils/tmdb_attribution.dart';
import '../details/movie_details_screen.dart';
import '../filters/genre_filter_sheet.dart';
import 'bloc/movie_list_bloc.dart';

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

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MovieListBloc>(
      create: (BuildContext context) => MovieListBloc(
        repository: DependencyScope.of(context).movieRepository,
      )..add(const MovieListStarted()),
      child: const _MovieListView(),
    );
  }
}
