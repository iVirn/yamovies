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
  bool _cancelSubscriptionOnDispose = false;
  bool _useSecureStorage = true;
  bool _airplaneMode = false;
  bool _simulateConflict = false;

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

  /// Демо «утечка подписки»: отменять ли подписку экрана фильма в `dispose`.
  bool get cancelSubscriptionOnDispose => _cancelSubscriptionOnDispose;

  set cancelSubscriptionOnDispose(bool value) {
    if (_cancelSubscriptionOnDispose == value) {
      return;
    }

    _cancelSubscriptionOnDispose = value;
    notifyListeners();
  }

  /// Демо «где лежит токен»: какое хранилище считается основным.
  bool get useSecureStorage => _useSecureStorage;

  set useSecureStorage(bool value) {
    if (_useSecureStorage == value) {
      return;
    }

    _useSecureStorage = value;
    notifyListeners();
  }

  /// Демо «режим полёта»: сеть выключена внутри приложения, чтобы не гасить
  /// Wi-Fi на лекции. Для кода это обычный `SocketException`.
  bool get airplaneMode => _airplaneMode;

  set airplaneMode(bool value) {
    if (_airplaneMode == value) {
      return;
    }

    _airplaneMode = value;
    notifyListeners();
  }

  /// Сервер отвечает 409 на операции по фильмам с чётным id: «пока вы были
  /// офлайн, с другого устройства этот фильм убрали».
  bool get simulateConflict => _simulateConflict;

  set simulateConflict(bool value) {
    if (_simulateConflict == value) {
      return;
    }

    _simulateConflict = value;
    notifyListeners();
  }
}
