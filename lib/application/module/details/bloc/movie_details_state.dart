part of 'movie_details_bloc.dart';

sealed class MovieDetailsState {
  const MovieDetailsState();
}

final class MovieDetailsLoadingState extends MovieDetailsState {
  const MovieDetailsLoadingState();
}

final class MovieDetailsSuccessState extends MovieDetailsState {
  const MovieDetailsSuccessState({required this.movie});

  final Movie movie;
}
