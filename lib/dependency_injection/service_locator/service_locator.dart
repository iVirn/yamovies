final class ServiceLocator {
  final Map<Type, Object> _registry = {};

  void register<T extends Object>(T instance) {
    _registry[T] = instance;
  }

  T get<T extends Object>() {
    final instance = _registry[T];
    if (instance == null) {
      throw StateError('Тип $T не зарегистрирован в ServiceLocator');
    }
    return instance as T;
  }

  void reset() => _registry.clear();
}

final ServiceLocator locator = ServiceLocator();
