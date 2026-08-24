import '../../application/demo_settings.dart';
import '../../data/favorites_service.dart';
import '../../data/movie_repository.dart';

/// Контейнер зависимостей приложения.
///
/// Аннотации `@immutable` здесь нет намеренно: сам контейнер не меняется,
/// но держит он живые объекты с состоянием — объявить их неизменяемыми
/// значило бы соврать. Зато у контейнера есть владелец, который закрывает
/// всё, что тот раздал: [dispose].
final class DependencyContainer {
  const DependencyContainer({
    required this.movieRepository,
    required this.favoritesService,
    required this.demoSettings,
  });

  final MovieRepository movieRepository;
  final FavoritesService favoritesService;
  final DemoSettings demoSettings;

  /// Освободить всё, что живёт дольше одного экрана.
  ///
  /// При закрытии процесса ресурсы освободит ОС, но при hot restart
  /// и в тестах это единственный способ не оставить за собой подписки.
  Future<void> dispose() async {
    demoSettings.dispose();
  }
}
