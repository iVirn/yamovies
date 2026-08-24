# YaMovies — Flutter lecture 1 demo

This repository contains the tag-by-tag demo for the first Flutter lecture.
`lecture-1-finish` adds the lecture's local-state checkpoint. Stateful
`MovieListScreen` stores favorite movie ids in a `Set<int>` and rebuilds via
`setState()`, while each `MovieCard` remains stateless and reports taps through
a callback. Favorites are intentionally local and reset on app restart.

## Requirements

- Flutter 3.44.4 stable
- Dart 3.12.2

The exact Flutter version is pinned in `.fvmrc`:

```bash
fvm install 3.44.4
fvm flutter pub get
fvm flutter run
```

If FVM is not used, verify that `flutter --version` reports Flutter 3.44.4.

## Validate this tag

```bash
shasum -a 256 -c docs/tmdb_resources/SHA256SUMS
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Resources and attribution

The fixture is a curated six-movie snapshot shaped like TMDB API v3 responses;
it is not a complete `/movie/top_rated` page. Resource provenance and checksum
instructions are in [docs/tmdb_resources/README.md](docs/tmdb_resources/README.md).

This product uses the TMDB API but is not endorsed or certified by TMDB.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for complete attribution.

---

# Примеры к лекции «Асинхронность, сеть и данные»

Каждый пример — отдельная ветка `async-NN-…`, растущая из предыдущей: приложение
не переписывается заново, а обрастает тем, что разбирается на слайдах. Ветка
`async-01` начинается от `feature/async-navigation-lecture`.

| Ветка | Раздел лекции | Что показывает |
|---|---|---|
| `async-01-event-loop-isolate` | 01. Event loop и Future | тяжёлый расчёт в UI-изоляте против `Isolate.run` |

## Запуск

Ключ TMDB передаётся сборкой, а не лежит в коде:

```bash
flutter run --dart-define=TMDB_API_KEY=<ключ>
```

В Android Studio то же самое уже прописано в конфигурации запуска
**YaMovies (TMDB)** — файл [.run/YaMovies (TMDB).run.xml](.run), она подхватится
автоматически при открытии проекта.

> [!WARNING]
> Ключ лежит в конфигурации запуска открытым текстом и попадает в историю git.
> Это осознанный компромисс учебного репозитория: после курса ключ стоит
> отозвать в кабинете TMDB.

## async-01-event-loop-isolate

Демо «UI замирает» из первого раздела: одна и та же CPU-работа сначала блокирует
UI-изолят, потом уезжает в `Isolate.run`.

**Добавлено**

- `lib/domain/catalog_stats.dart` — «индекс каталога»: чистая функция
  `computeCatalogStats` без замыканий и ссылок на UI (такую можно отдать
  в `Isolate.run` или `compute` как есть) плюс модели `CatalogStatsRequest`
  и `CatalogStats`. Вес расчёта задаётся `CatalogStatsRequest.defaultPasses` —
  если на вашей машине лаг незаметен, поднимите значение.
- `lib/application/demo_settings.dart` — `DemoSettings`, общий `ChangeNotifier`
  с переключателями демо. Дальше каждый пример лекции добавляет сюда ровно один
  флаг «как неправильно / как правильно».
- `lib/application/module/list/_catalog_stats_panel.dart` — панель на ленте:
  кнопка «пересчитать», переключатель изолята, результат со временем расчёта
  и два живых индикатора (`LinearProgressIndicator` и вращающаяся иконка).
  По ним и видно, что UI-изолят встал: анимация замирает вместе с ним.

**Изменено**

- `MovieListController` получил `recalculateStats`: замер `Stopwatch` и развилка
  «считать здесь» против `await Isolate.run(...)`. Метод объявлен `async`
  специально — видно, что `async` сам по себе от блокировки не спасает.
- `DependencyContainer` и `main.dart` — в контейнер добавлен `DemoSettings`.
- `_MovieListContent` — панель встроена между галереей и фильтрами.
- `test/widget_test.dart` — панель занимает место на экране, поэтому вьюпорт
  в тестах вырос до 1600 px, а прокрутка — до 900 px. `pumpAndSettle` заменён
  на `_pumpFrames`: с бесконечной анимацией дерево виджетов не «успокаивается»
  никогда, и `pumpAndSettle` ушёл бы в таймаут.

**Как показывать**

1. Переключатель выключен → «Пересчитать»: анимация встаёт, тапы не проходят,
   в панели — время расчёта на UI-изоляте.
2. DevTools → Performance: один кадр длиной почти в секунду, красная полоса
   UI-потока.
3. Переключатель включён → «Пересчитать»: то же время расчёта, но анимация
   не прерывается, кадры укладываются в 16 мс.
