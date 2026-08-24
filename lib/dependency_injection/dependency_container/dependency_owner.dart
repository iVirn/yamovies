import 'dart:async';

import 'package:flutter/material.dart';

import 'dependency_container.dart';
import 'dependency_scope.dart';

/// Владелец контейнера зависимостей.
///
/// `DependencyScope` только раздаёт зависимости вниз по дереву, а закрывать
/// их должен кто-то один. Этот виджет и есть тот один: он держит контейнер
/// и освобождает его в `dispose` — при hot restart и в тестах это
/// единственный способ не оставить за собой живые подписки.
class DependencyOwner extends StatefulWidget {
  const DependencyOwner({
    required this.container,
    required this.child,
    super.key,
  });

  final DependencyContainer container;
  final Widget child;

  @override
  State<DependencyOwner> createState() => _DependencyOwnerState();
}

class _DependencyOwnerState extends State<DependencyOwner> {
  @override
  void dispose() {
    unawaited(widget.container.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DependencyScope(container: widget.container, child: widget.child);
  }
}
