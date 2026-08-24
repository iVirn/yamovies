import 'package:flutter/widgets.dart';

import '../../application/demo_settings.dart';
import '../../data/movie_repository.dart';

@immutable
final class DependencyContainer {
  const DependencyContainer({
    required this.movieRepository,
    required this.demoSettings,
  });

  final MovieRepository movieRepository;
  final DemoSettings demoSettings;
}
