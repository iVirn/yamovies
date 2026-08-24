part of 'movie_details_bloc.dart';

sealed class MovieDetailsEvent extends Equatable {
  const MovieDetailsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class MovieDetailsStarted extends MovieDetailsEvent {
  const MovieDetailsStarted();
}

/// Перезагрузка экрана: тем же кодом, но с текущими настройками демо.
final class MovieDetailsReloaded extends MovieDetailsEvent {
  const MovieDetailsReloaded();
}
