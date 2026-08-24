part of 'movie_details_bloc.dart';

sealed class MovieDetailsState extends Equatable {
  const MovieDetailsState();

  @override
  List<Object?> get props => <Object?>[];
}

final class MovieDetailsLoadingState extends MovieDetailsState {
  const MovieDetailsLoadingState();
}

final class MovieDetailsSuccessState extends MovieDetailsState {
  const MovieDetailsSuccessState({required this.bundle});

  final MovieDetailsBundle bundle;

  @override
  List<Object?> get props => <Object?>[bundle];
}

final class MovieDetailsFailureState extends MovieDetailsState {
  const MovieDetailsFailureState({
    required this.message,
    required this.canRetry,
  });

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => <Object?>[message, canRetry];
}
