/// Ошибка, которую вернул сервер: он ответил, но кодом ошибки.
///
/// `DioException` дальше сетевого слоя не уезжает — иначе экраны начнут
/// разбирать статусы сами. Наверх поднимаются только четыре типа:
/// [ApiException], `SocketException`, `TimeoutException` и `FormatException`.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.path,
    this.serverMessage,
  });

  final int statusCode;
  final String path;
  final String? serverMessage;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() =>
      'ApiException($statusCode, $path${serverMessage == null ? '' : ', $serverMessage'})';
}
