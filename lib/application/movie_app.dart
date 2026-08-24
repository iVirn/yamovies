import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamovies/application/router/app_router.dart';

class MovieApp extends StatefulWidget {
  const MovieApp({super.key});

  @override
  State<MovieApp> createState() => _MovieAppState();
}

class _MovieAppState extends State<MovieApp> {
  /// Роутер создаётся один раз на всё приложение: пересозданный в `build`,
  /// он терял бы стек на каждой перерисовке.
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'YaMovies',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
        useMaterial3: true,
      ),
    );
  }
}
