import 'package:flutter/foundation.dart';

/// Переключатели лекционных демо.
///
/// Живут в [DependencyContainer], потому что одно и то же демо переключается
/// с одного экрана, а показывает себя на другом. Каждый пример лекции
/// добавляет сюда ровно один флаг — «как неправильно» против «как правильно».
class DemoSettings extends ChangeNotifier {
  DemoSettings();

  bool _computeStatsInIsolate = false;

  /// Демо «UI замирает»: считать индекс каталога в отдельном изоляте
  /// (`Isolate.run`) вместо UI-изолята.
  bool get computeStatsInIsolate => _computeStatsInIsolate;

  set computeStatsInIsolate(bool value) {
    if (_computeStatsInIsolate == value) {
      return;
    }

    _computeStatsInIsolate = value;
    notifyListeners();
  }
}
