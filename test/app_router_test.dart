import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamovies/application/router/app_router.dart';

/// Диплинк восстанавливает стек только тогда, когда маршрут вложен в родителя.
/// Это и проверяем: плоский `/movie/:id/cast` открыл бы один экран, под которым
/// пусто, и «назад» вывалился бы из приложения.
///
/// Живая проверка — на устройстве и обязательно на холодном старте:
/// `adb shell am start -a android.intent.action.VIEW -d "yamovies://movie/278/cast"`.
void main() {
  test('маршрут актёров вложен в маршрут фильма, а тот — в ленту', () {
    final GoRouter router = createAppRouter();
    addTearDown(router.dispose);

    final GoRoute home = router.configuration.routes.single as GoRoute;
    expect(home.path, '/');

    final GoRoute movie =
        home.routes.whereType<GoRoute>().firstWhere(
              (GoRoute route) => route.path == 'movie/:id',
            );
    expect(movie.routes.whereType<GoRoute>().map((GoRoute r) => r.path), <String>[
      'cast',
    ]);
  });

  test('диплинк со схемой приводится к пути приложения', () {
    // Так ссылку присылает система: первый сегмент попадает в хост,
    // и без нормализации путь оказался бы `/278/cast`.
    expect(
      normalizeDeepLink(Uri.parse('yamovies://movie/278/cast')),
      '/movie/278/cast',
    );
    expect(normalizeDeepLink(Uri.parse('yamovies://movie/278')), '/movie/278');
    expect(normalizeDeepLink(Uri.parse('yamovies://search')), '/search');

    // Форма с тремя слэшами разбирается сама — трогать её не нужно.
    expect(normalizeDeepLink(Uri.parse('yamovies:///movie/278/cast')), isNull);

    // Обычная навигация внутри приложения идёт мимо нормализации.
    expect(normalizeDeepLink(Uri.parse('/movie/278/cast')), isNull);
    expect(normalizeDeepLink(Uri.parse('https://example.com/movie/1')), isNull);
  });

  test('пути собираются из констант, а не из строк по месту', () {
    expect(AppRoutes.movie(278), '/movie/278');
    expect(AppRoutes.movieCast(278), '/movie/278/cast');
  });

  test('все демо-экраны лежат под лентой', () {
    final GoRouter router = createAppRouter();
    addTearDown(router.dispose);

    final GoRoute home = router.configuration.routes.single as GoRoute;
    final Iterable<String> children = home.routes.whereType<GoRoute>().map(
      (GoRoute route) => route.path,
    );

    expect(
      children,
      containsAll(<String>['search', 'cache', 'network', 'token', 'movie/:id']),
    );
  });
}
