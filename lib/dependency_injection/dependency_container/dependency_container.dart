import 'package:flutter/widgets.dart';

import '../../data/movie_repository.dart';

@immutable
final class DependencyContainer {
  const DependencyContainer({required this.movieRepository});

  final MovieRepository movieRepository;
}
