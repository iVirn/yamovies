import 'package:flutter_test/flutter_test.dart';
import 'package:movie_database/movie_database.dart';
import 'package:yamovies/application/demo_settings.dart';
import 'package:yamovies/data/favorites_service.dart';
import 'package:yamovies/data/favorites_sync_api.dart';
import 'package:yamovies/data/sync_service.dart';

void main() {
  late DemoSettings demoSettings;
  late AppDatabase database;
  late FavoritesSyncApi api;
  late SyncService syncService;
  late FavoritesService favorites;

  setUp(() {
    demoSettings = DemoSettings();
    database = AppDatabase(NativeDatabase.memory());
    api = FavoritesSyncApi(demoSettings: demoSettings, latency: Duration.zero);
    syncService = SyncService(database: database, api: api);
    favorites = FavoritesService(database: database, syncService: syncService);
  });

  tearDown(() async {
    // Даём фоновому проходу очереди договорить, иначе он постучится
    // в уже закрытую базу.
    await pumpEventQueue();
    await favorites.dispose();
    await syncService.dispose();
    await database.close();
  });

  test('переключение офлайн ложится в базу и в очередь', () async {
    demoSettings.airplaneMode = true;

    await favorites.toggle(278);
    await pumpEventQueue();

    expect(await database.readFavoriteIds(), <int>{278});
    expect((await database.readPendingOps()).single.movieId, 278);
  });

  test('очередь уходит, когда сеть возвращается', () async {
    demoSettings.airplaneMode = true;
    await favorites.toggle(278);
    // `toggle` уже толкнул очередь — дожидаемся именно того прохода.
    await pumpEventQueue();

    // Сети нет: операция осталась и получила отложенный повтор.
    expect((await database.readAllOps()).single.attempts, 1);

    demoSettings.airplaneMode = false;
    // Повтор запланирован на будущее, поэтому сначала снимаем задержку.
    await database.rescheduleOp(
      (await database.readAllOps()).single.id,
      delay: Duration.zero,
    );
    await syncService.drain();

    expect(await database.readAllOps(), isEmpty);
    expect(api.appliedCount, 1);
  });

  test('409 разрешается версией сервера', () async {
    demoSettings.simulateConflict = true;

    // id чётный — сервер скажет «этот фильм уже не в избранном».
    await favorites.toggle(278);
    await pumpEventQueue();

    expect(await database.readFavoriteIds(), isEmpty);
    expect(await database.readAllOps(), isEmpty);
  });

  test('повтор с тем же ключом идемпотентности не дублирует операцию', () async {
    demoSettings.airplaneMode = true;
    await favorites.toggle(129);
    await pumpEventQueue();
    demoSettings.airplaneMode = false;

    final PendingOp op = (await database.readAllOps()).single;

    await api.apply(op, idempotencyKey: op.idemKey);
    await api.apply(op, idempotencyKey: op.idemKey);

    expect(api.appliedCount, 1);
  });
}
