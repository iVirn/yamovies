import 'package:flutter/material.dart';

import '../../../components/poster_fallback.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_formatters.dart';
import '../../view_model_scope.dart';
import 'movie_details_view_model.dart';

part '_details_favorite_action.dart';
part '_details_favorite_button.dart';
part '_details_poster.dart';
part '_expandable_overview.dart';
part '_meta_pill.dart';
part '_movie_details_view.dart';
part '_overview_text.dart';

class MovieDetailsScreen extends StatefulWidget {
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
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late final MovieDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MovieDetailsViewModel(
      isFavorite: widget.isFavorite,
      onFavoriteTap: widget.onFavoriteTap,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelScope<MovieDetailsViewModel>(
      viewModel: _viewModel,
      child: _MovieDetailsView(
        movie: widget.movie,
        genreNames: widget.genreNames,
        posterAssetPath: widget.posterAssetPath,
      ),
    );
  }
}
