import 'package:flutter/material.dart';

class ViewModelScope<T extends ChangeNotifier> extends InheritedNotifier<T> {
  const ViewModelScope({
    required T viewModel,
    required super.child,
    super.key,
  }) : super(notifier: viewModel);

  T get viewModel => notifier!;

  static T of<T extends ChangeNotifier>(
    BuildContext context, {
    bool listen = true,
  }) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<ViewModelScope<T>>()
        : context.getInheritedWidgetOfExactType<ViewModelScope<T>>();
    assert(scope != null, 'ViewModelScope<$T> не найден в дереве виджетов');
    return scope!.notifier!;
  }
}
