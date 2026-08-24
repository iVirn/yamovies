// ignore_for_file: avoid_print

class Publisher {
  final List<Observer> _observers = [];
  int _count = 0;

  int get count => _count;

  void subscribe(Observer observer) {
    _observers.add(observer);
  }

  void unsubscribe(Observer observer) {
    _observers.remove(observer);
  }

  void increment() {
    _count++;
    _notify();
  }

  void _notify() {
    for (final observer in _observers) {
      observer.update(_count);
    }
  }
}

abstract interface class Observer {
  const Observer();

  void update(int count);
}

class LoggingObserver implements Observer {
  const LoggingObserver(this.name);

  final String name;

  @override
  void update(int count) {
    print('$name получил новое значение: $count');
  }
}

void main() {
  final publisher = Publisher();

  final first = LoggingObserver('Подписчик A');
  final second = LoggingObserver('Подписчик B');

  publisher.subscribe(first);
  publisher.subscribe(second);

  publisher.increment();
  publisher.increment();

  publisher.unsubscribe(second);

  publisher.increment();
}
