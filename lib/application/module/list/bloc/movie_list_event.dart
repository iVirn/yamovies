part of 'movie_list_bloc.dart';

sealed class MovieListEvent extends Equatable {
  const MovieListEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class MovieListStarted extends MovieListEvent {
  const MovieListStarted();
}

final class MovieListRefreshed extends MovieListEvent {
  const MovieListRefreshed();
}
