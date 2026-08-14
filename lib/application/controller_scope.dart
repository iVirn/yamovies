import 'package:flutter/material.dart';

import 'controller.dart';

class ControllerScope<T extends Controller> extends InheritedNotifier<T> {
  const ControllerScope({
    required T controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  T get controller => notifier!;

  static T of<T extends Controller>(
    BuildContext context, {
    bool listen = true,
  }) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<ControllerScope<T>>()
        : context.getInheritedWidgetOfExactType<ControllerScope<T>>();
    assert(scope != null, 'ControllerScope<$T> не найден в дереве виджетов');
    return scope!.notifier!;
  }
}
