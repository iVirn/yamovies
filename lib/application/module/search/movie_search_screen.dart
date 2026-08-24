import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../components/movie_poster.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_formatters.dart';
import '../../controller_scope.dart';
import '../../router/app_router.dart';
import 'movie_search_controller.dart';

part '_search_field.dart';
part '_search_mode_selector.dart';
part '_search_request_log.dart';
part '_search_results.dart';

/// Демо «Строка поиска»: один и тот же экран в трёх режимах.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  late final MovieSearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MovieSearchController(
      repository: DependencyScope.of(context).movieRepository,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerScope<MovieSearchController>(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('Search movies')),
        body: Column(
          children: <Widget>[
            const _SearchField(),
            const _SearchModeSelector(),
            const _SearchRequestLog(),
            const Divider(height: 1),
            Expanded(child: _SearchResults(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
