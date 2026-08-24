import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../module/cache/cache_inspector_screen.dart';
import '../module/details/movie_cast_screen.dart';
import '../module/details/movie_details_screen.dart';
import '../module/list/movie_list_screen.dart';
import '../module/network/network_demo_screen.dart';
import '../module/search/movie_search_screen.dart';
import '../module/storage/token_storage_screen.dart';

/// Маршруты приложения.
///
/// Вложенность маршрутов и есть маппинг ссылки в стек: `/movie/278/cast`
/// разворачивается в три страницы — лента, фильм, актёры, — а не в одну.
/// Проверять это нужно на **холодном старте**:
///
/// ```bash
/// adb shell am start -a android.intent.action.VIEW -d "yamovies://movie/278/cast"
/// xcrun simctl openurl booted "yamovies://movie/278/cast"
/// ```
///
/// `go_router` — это готовая реализация четырёх интерфейсов Router:
/// `RouteInformationProvider`, `RouteInformationParser`, `RouterDelegate`
/// и `BackButtonDispatcher`.
GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.home,
  // В логе видно путь ссылки до экрана — это и показываем на демо.
  debugLogDiagnostics: true,
  // Диплинк приезжает сюда целиком, вместе со схемой, а маршруты
  // сопоставляются только с путём. Для `yamovies://movie/278/cast` путь —
  // это `/278/cast`, потому что `movie` система считает хостом. Приводим
  // ссылку к виду, который роутер узнаёт.
  redirect: (BuildContext context, GoRouterState state) =>
      normalizeDeepLink(state.uri),
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.home,
      builder: (BuildContext context, GoRouterState state) =>
          const MovieListScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'search',
          builder: (BuildContext context, GoRouterState state) =>
              const MovieSearchScreen(),
        ),
        GoRoute(
          path: 'cache',
          builder: (BuildContext context, GoRouterState state) =>
              const CacheInspectorScreen(),
        ),
        GoRoute(
          path: 'network',
          builder: (BuildContext context, GoRouterState state) =>
              const NetworkDemoScreen(),
        ),
        GoRoute(
          path: 'token',
          builder: (BuildContext context, GoRouterState state) =>
              const TokenStorageScreen(),
        ),
        GoRoute(
          path: 'movie/:id',
          builder: (BuildContext context, GoRouterState state) =>
              MovieDetailsScreen(movieId: _movieId(state)),
          routes: <RouteBase>[
            // Вложенный маршрут → под «Актёрами» сам собой оказывается
            // экран фильма, а под ним — лента.
            GoRoute(
              path: 'cast',
              builder: (BuildContext context, GoRouterState state) =>
                  MovieCastScreen(movieId: _movieId(state)),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    appBar: AppBar(title: const Text('Не туда')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Ссылка «${state.uri}» ни на что не ведёт.\n'
          'Рабочий пример: ${AppRoutes.scheme}://movie/278/cast',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ),
);

int _movieId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

/// Привести диплинк к пути приложения.
///
/// Схема без хоста (`yamovies:///movie/278/cast`) разбирается сама, а вот
/// в `yamovies://movie/278/cast` первый сегмент достаётся хосту — и путь
/// теряет начало. Возвращает `null`, если менять нечего: так `redirect`
/// понимает «оставь как есть».
String? normalizeDeepLink(Uri uri) {
  if (uri.scheme != AppRoutes.scheme || uri.host.isEmpty) {
    return null;
  }

  final String path = '/${uri.host}${uri.path}';
  final String query = uri.hasQuery ? '?${uri.query}' : '';

  return '$path$query';
}

/// Пути в одном месте: строку легко опечатать, а константу — нет.
abstract final class AppRoutes {
  /// Схема диплинков; она же прописана в AndroidManifest и Info.plist.
  static const String scheme = 'yamovies';

  static const String home = '/';
  static const String search = '/search';
  static const String cache = '/cache';
  static const String network = '/network';
  static const String token = '/token';

  static String movie(int id) => '/movie/$id';

  static String movieCast(int id) => '/movie/$id/cast';
}
