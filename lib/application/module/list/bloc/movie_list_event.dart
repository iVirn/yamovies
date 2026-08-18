part of 'movie_list_bloc.dart';

sealed class MovieListEvent {
  const MovieListEvent();
}

final class MovieListStarted extends MovieListEvent {
  const MovieListStarted();
}
