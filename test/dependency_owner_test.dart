import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamovies/application/demo_settings.dart';
import 'package:movie_network/movie_network.dart';
import 'package:yamovies/data/favorites_service.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_container.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_owner.dart';

void main() {
  testWidgets('владелец закрывает контейнер, когда уходит из дерева', (
    WidgetTester tester,
  ) async {
    final DemoSettings demoSettings = DemoSettings();
    final NetworkEventBus eventBus = NetworkEventBus();
    final TokenStorage tokenStorage = InMemoryTokenStorage();
    final DependencyContainer container = DependencyContainer(
      movieRepository: const MovieRepositoryMock(),
      favoritesService: FavoritesService(),
      tokenStorage: tokenStorage,
      tokenRefresher: TokenRefresher(
        storage: tokenStorage,
        fetchFreshToken: () async => null,
        eventBus: eventBus,
      ),
      networkEventBus: eventBus,
      demoSettings: demoSettings,
    );

    await tester.pumpWidget(
      DependencyOwner(container: container, child: const SizedBox.shrink()),
    );
    await tester.pump();

    // Пока владелец в дереве, зависимости живы.
    demoSettings.computeStatsInIsolate = true;
    expect(demoSettings.computeStatsInIsolate, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    // Владелец ушёл — контейнер закрыт: обращение к закрытому
    // ChangeNotifier бросает ошибку, и это именно то, чего мы ждём.
    expect(
      () => demoSettings.addListener(() {}),
      throwsA(isA<FlutterError>()),
    );
  });
}
