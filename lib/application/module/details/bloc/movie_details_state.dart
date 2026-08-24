part of 'movie_details_bloc.dart';

sealed class MovieDetailsState {
  const MovieDetailsState();
}

final class MovieDetailsLoadingState extends MovieDetailsState {
  const MovieDetailsLoadingState();
}

final class MovieDetailsSuccessState extends MovieDetailsState {
  const MovieDetailsSuccessState({required this.bundle});

  final MovieDetailsBundle bundle;
}

final class MovieDetailsFailureState extends MovieDetailsState {
  const MovieDetailsFailureState({
    required this.message,
    required this.canRetry,
  });

  final String message;
  final bool canRetry;
}
