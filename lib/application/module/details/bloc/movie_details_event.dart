part of 'movie_details_bloc.dart';

sealed class MovieDetailsEvent {
  const MovieDetailsEvent();
}

final class MovieDetailsStarted extends MovieDetailsEvent {
  const MovieDetailsStarted();
}
