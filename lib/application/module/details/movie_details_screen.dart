import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/poster_fallback.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_formatters.dart';
import 'bloc/movie_details_bloc.dart';

part '_details_favorite_action.dart';
part '_details_favorite_button.dart';
part '_details_poster.dart';
part '_expandable_overview.dart';
part '_meta_pill.dart';
part '_movie_details_view.dart';
part '_overview_text.dart';

class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({
    required this.movie,
    required this.genreNames,
    required this.posterAssetPath,
    required this.isFavorite,
    required this.onFavoriteTap,
    super.key,
  });

  final Movie movie;
  final List<String> genreNames;
  final String? posterAssetPath;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MovieDetailsBloc>(
      create: (BuildContext context) => MovieDetailsBloc(
        isFavorite: isFavorite,
        onFavoriteTap: onFavoriteTap,
      ),
      child: _MovieDetailsView(
        movie: movie,
        genreNames: genreNames,
        posterAssetPath: posterAssetPath,
      ),
    );
  }
}
