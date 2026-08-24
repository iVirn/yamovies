import 'package:flutter/foundation.dart';

/// Счётчики для демо «утечка подписки».
///
/// В настоящем приложении это видно только в DevTools → Memory через полчаса
/// работы. Здесь те же цифры вынесены на экран: сколько подписок ещё живо
/// и сколько раз колбэк сработал у экрана, которого уже нет.
abstract final class LeakProbe {
  /// Открытые подписки на поток избранного, созданные вручную.
  static final ValueNotifier<int> liveSubscriptions = ValueNotifier<int>(0);

  /// Срабатывания колбэка после `dispose` — те самые «звонки на снесённый дом».
  static final ValueNotifier<int> zombieCallbacks = ValueNotifier<int>(0);

  static void subscriptionOpened() => liveSubscriptions.value++;

  static void subscriptionClosed() => liveSubscriptions.value--;

  static void zombieCallback() => zombieCallbacks.value++;

  static void reset() {
    liveSubscriptions.value = 0;
    zombieCallbacks.value = 0;
  }
}
