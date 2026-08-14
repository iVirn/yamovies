import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'movie_details_event.dart';
part 'movie_details_state.dart';

class MovieDetailsBloc extends Bloc<MovieDetailsEvent, MovieDetailsState> {
  MovieDetailsBloc({
    required bool isFavorite,
    required VoidCallback onFavoriteTap,
  }) : _onFavoriteTap = onFavoriteTap, // ignore: prefer_initializing_formals
       super(
         isFavorite
             ? const MovieDetailsFavoriteState()
             : const MovieDetailsNotFavoriteState(),
       ) {
    on<MovieDetailsFavoriteToggled>(_onFavoriteToggled);
  }

  final VoidCallback _onFavoriteTap;

  void _onFavoriteToggled(
    MovieDetailsFavoriteToggled event,
    Emitter<MovieDetailsState> emit,
  ) {
    _onFavoriteTap();
    emit(switch (state) {
      MovieDetailsFavoriteState() => const MovieDetailsNotFavoriteState(),
      MovieDetailsNotFavoriteState() => const MovieDetailsFavoriteState(),
    });
  }
}
