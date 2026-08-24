/// Единственный владелец токена.
///
/// Единственный — важное слово: если писать токен из двух мест, получится
/// гонка за хранилищем, и один экран затрёт токен, который только что
/// обновил другой.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  Future<void> clear();
}

/// Хранилище в памяти: живёт до перезапуска приложения.
///
/// Дальше по курсу его сменят `shared_preferences` и `flutter_secure_storage` —
/// интерфейс останется тем же.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({String? initialToken}) : _token = initialToken;

  String? _token;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<void> writeAccessToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
