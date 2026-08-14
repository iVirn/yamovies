part of 'movie_details_bloc.dart';

sealed class MovieDetailsEvent {
  const MovieDetailsEvent();
}

final class MovieDetailsFavoriteToggled extends MovieDetailsEvent {
  const MovieDetailsFavoriteToggled();
}
