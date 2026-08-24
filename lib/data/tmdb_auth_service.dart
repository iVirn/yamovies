import 'tmdb_config.dart';

/// Заглушка сервера авторизации.
///
/// У TMDB v3 нет refresh-флоу: ключ выдаётся в кабинете и не протухает.
/// Поэтому «сервер, который выдаёт свежий токен» живёт здесь — он просто
/// возвращает настоящий ключ после задержки. Всё остальное в цепочке
/// (401 от сервера, очередь ожидающих, повтор запроса) — настоящее.
class TmdbAuthService {
  const TmdbAuthService({
    this.latency = const Duration(milliseconds: 700),
  });

  final Duration latency;

  Future<String?> issueAccessToken() =>
      Future<String?>.delayed(latency, () => TmdbConfig.apiKey);
}
