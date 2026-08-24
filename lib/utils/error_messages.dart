import 'dart:async';
import 'dart:io';

import 'package:movie_network/movie_network.dart';

/// Четыре типа ошибок, которые нужно различать, — и четыре разных сообщения.
///
/// `catch (e)` без типа превратил бы их в одинаковое «что-то пошло не так»
/// и лишил пользователя кнопки «повторить», а нас — диагностики.
String describeLoadError(Object error) => switch (error) {
  SocketException() => 'No connection. Check the network and try again.',
  TimeoutException() => 'The server did not answer in time. Try again.',
  FormatException() => 'Unexpected response format. This one is on us.',
  ApiException(statusCode: 401) =>
    'TMDB rejected the API key. Check --dart-define=TMDB_API_KEY.',
  ApiException(statusCode: 404) => 'TMDB has no data for this request.',
  ApiException(:final int statusCode, :final String? serverMessage) =>
    serverMessage ?? 'TMDB answered with $statusCode.',
  _ => 'Something went wrong: $error',
};

/// Можно ли осмысленно предложить кнопку «повторить».
bool isRetryable(Object error) => switch (error) {
  SocketException() || TimeoutException() => true,
  ApiException(:final int statusCode) => statusCode >= 500,
  _ => false,
};
