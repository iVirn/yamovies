part of 'movie_list_bloc.dart';

/// Состояния сравниваются по значению: иначе `BlocBuilder` перерисовывал бы
/// экран на каждый эмит, даже когда данные те же самые.
sealed class MovieListState extends Equatable {
  const MovieListState();

  @override
  List<Object?> get props => <Object?>[];
}

final class MovieListLoadingState extends MovieListState {
  const MovieListLoadingState();
}

final class MovieListSuccessState extends MovieListState {
  const MovieListSuccessState({required this.movies, required this.genres});

  final List<Movie> movies;
  final List<Genre> genres;

  @override
  List<Object?> get props => <Object?>[movies, genres];
}

final class MovieListFailureState extends MovieListState {
  const MovieListFailureState({required this.message, required this.canRetry});

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => <Object?>[message, canRetry];
}
