import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamovies/application/demo_settings.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_container.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_owner.dart';

void main() {
  testWidgets('владелец закрывает контейнер, когда уходит из дерева', (
    WidgetTester tester,
  ) async {
    final DemoSettings demoSettings = DemoSettings();
    final DependencyContainer container = DependencyContainer(
      movieRepository: const MovieRepositoryMock(),
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
