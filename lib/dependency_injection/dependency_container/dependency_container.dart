import 'package:movie_database/movie_database.dart';
import 'package:movie_network/movie_network.dart';

import '../../application/demo_settings.dart';
import '../../data/favorites_service.dart';
import '../../data/movie_repository.dart';
import '../../data/sync_service.dart';
import '../../data/token_storages.dart';

/// Контейнер зависимостей приложения.
///
/// Аннотации `@immutable` здесь нет намеренно: сам контейнер не меняется,
/// но держит он живые объекты с состоянием — объявить их неизменяемыми
/// значило бы соврать. Зато у контейнера есть владелец, который закрывает
/// всё, что тот раздал: [dispose].
final class DependencyContainer {
  const DependencyContainer({
    required this.movieRepository,
    required this.database,
    required this.favoritesService,
    required this.syncService,
    required this.tokenStorage,
    required this.tokenRefresher,
    required this.networkEventBus,
    required this.demoSettings,
  });

  final MovieRepository movieRepository;

  /// Локальный кэш: drift поверх SQLite.
  final AppDatabase database;
  final FavoritesService favoritesService;

  /// Разбор очереди изменений: то, что пользователь сделал офлайн.
  final SyncService syncService;

  /// Единственный владелец токена — его же подменяет демо «401 и refresh».
  final TokenStorage tokenStorage;
  final TokenRefresher tokenRefresher;

  /// Шина событий сетевого слоя: интерсепторы пишут, экран демо читает.
  final NetworkEventBus networkEventBus;
  final DemoSettings demoSettings;

  /// Освободить всё, что живёт дольше одного экрана.
  ///
  /// При закрытии процесса ресурсы освободит ОС, но при hot restart
  /// и в тестах это единственный способ не оставить за собой подписки.
  Future<void> dispose() async {
    final TokenStorage storage = tokenStorage;
    if (storage is SwitchableTokenStorage) {
      storage.dispose();
    }

    await favoritesService.dispose();
    await syncService.dispose();
    await database.close();
    await networkEventBus.dispose();
    demoSettings.dispose();
  }
}
