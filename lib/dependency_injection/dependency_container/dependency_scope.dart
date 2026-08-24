import 'package:flutter/material.dart';
import 'package:yamovies/dependency_injection/dependency_container/dependency_container.dart';

class DependencyScope extends InheritedWidget {
  const DependencyScope({
    required this.container,
    required super.child,
    super.key,
  });

  final DependencyContainer container;

  static DependencyContainer of(BuildContext context, {bool listen = false}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<DependencyScope>()
        : context.getInheritedWidgetOfExactType<DependencyScope>();
    assert(scope != null, 'DependencyScope не найден в дереве виджетов');
    return scope!.container;
  }

  @override
  bool updateShouldNotify(DependencyScope oldWidget) =>
      container != oldWidget.container;
}
