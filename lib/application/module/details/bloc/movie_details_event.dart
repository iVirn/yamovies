part of 'movie_details_bloc.dart';

sealed class MovieDetailsEvent {
  const MovieDetailsEvent();
}

final class MovieDetailsStarted extends MovieDetailsEvent {
  const MovieDetailsStarted();
}

/// Перезагрузка экрана: тем же кодом, но с текущими настройками демо.
final class MovieDetailsReloaded extends MovieDetailsEvent {
  const MovieDetailsReloaded();
}
