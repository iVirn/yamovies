import 'package:flutter/foundation.dart';

/// Переключатели лекционных демо.
///
/// Живут в [DependencyContainer], потому что одно и то же демо переключается
/// с одного экрана, а показывает себя на другом. Каждый пример лекции
/// добавляет сюда ровно один флаг — «как неправильно» против «как правильно».
class DemoSettings extends ChangeNotifier {
  DemoSettings();

  bool _computeStatsInIsolate = false;
  bool _parallelDetailsLoad = false;
  bool _eagerErrorOnDetails = true;
  bool _breakCastRequest = false;

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

  /// Демо «три запроса разом»: грузить экран фильма через `Future.wait`
  /// вместо трёх `await` подряд.
  bool get parallelDetailsLoad => _parallelDetailsLoad;

  set parallelDetailsLoad(bool value) {
    if (_parallelDetailsLoad == value) {
      return;
    }

    _parallelDetailsLoad = value;
    notifyListeners();
  }

  /// `eagerError: true` — упасть на первой ошибке, не дожидаясь остальных.
  bool get eagerErrorOnDetails => _eagerErrorOnDetails;

  set eagerErrorOnDetails(bool value) {
    if (_eagerErrorOnDetails == value) {
      return;
    }

    _eagerErrorOnDetails = value;
    notifyListeners();
  }

  /// Ломает запрос актёров: запрашивается заведомо несуществующий фильм.
  bool get breakCastRequest => _breakCastRequest;

  set breakCastRequest(bool value) {
    if (_breakCastRequest == value) {
      return;
    }

    _breakCastRequest = value;
    notifyListeners();
  }
}
