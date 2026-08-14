part of 'movie_details_bloc.dart';

sealed class MovieDetailsState {
  const MovieDetailsState();
}

final class MovieDetailsFavoriteState extends MovieDetailsState {
  const MovieDetailsFavoriteState();
}

final class MovieDetailsNotFavoriteState extends MovieDetailsState {
  const MovieDetailsNotFavoriteState();
}
