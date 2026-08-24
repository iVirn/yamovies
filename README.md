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

Демо «UI замирает»: одна и та же CPU-работа сначала блокирует UI-изолят,
потом уезжает в `Isolate.run`.

**Где смотреть в приложении**

Лента → карточка **«Lecture demos»** → блок **«Catalogue index»**: кнопка
пересчёта, переключатель изолята и два живых индикатора. По ним и видно,
что UI-изолят встал: анимация замирает вместе с ним.

**Файлы**

| Файл | Что в нём |
|---|---|
| `lib/domain/catalog_stats.dart` | «Индекс каталога»: чистая функция `computeCatalogStats` без замыканий и ссылок на UI — такую можно отдать в `Isolate.run` или `compute` как есть. Вес расчёта задаёт `CatalogStatsRequest.defaultPasses` |
| `lib/application/module/list/movie_list_controller.dart` | `recalculateStats`: замер `Stopwatch` и развилка «считать здесь» против `await Isolate.run(...)`. Метод объявлен `async` специально — видно, что `async` сам по себе от блокировки не спасает |
| `lib/application/module/list/_catalog_stats_panel.dart` | Панель демо: кнопка, переключатель, результат и «пульс кадров» — бесконечная анимация, по которой заметен фриз |
| `lib/application/demo_settings.dart` | `DemoSettings` — общий `ChangeNotifier` с переключателями демо. Дальше каждый пример добавляет сюда ровно один флаг |
| `lib/dependency_injection/dependency_container/dependency_container.dart` | Контейнер получил `DemoSettings` и метод `dispose`; аннотация `@immutable` снята — он держит объекты с состоянием |
| `lib/dependency_injection/dependency_container/dependency_owner.dart` | Владелец контейнера: раздаёт зависимости вниз и закрывает их, когда уходит из дерева |
| `lib/application/module/list/_movie_list_content.dart` | Панель встроена между галереей и фильтрами |
| `lib/application/module/details/_movie_details_content.dart` | Подпись на баннере фильма стала белой, схлопнутая шапка — чёрной |
| `lib/main.dart` | Сборка контейнера и запуск через `DependencyOwner` |
| `demo.sh` | Запуск примера, шаги демо и (в примере 10) отправка диплинка |
| `.run/YaMovies (TMDB).run.xml` | Конфигурация запуска Android Studio с ключом TMDB |
| `test/dependency_owner_test.dart` | Владелец закрывает контейнер, когда уходит из дерева |
| `test/widget_test.dart` | Вьюпорт вырос до 1600 px, `pumpAndSettle` заменён на `_pumpFrames`: с бесконечной анимацией дерево не «успокаивается» никогда |

**Как показывать**

1. Переключатель выключен → «Пересчитать»: анимация встаёт, тапы не проходят,
   в панели — время расчёта на UI-изоляте.
2. DevTools → Performance: один кадр длиной почти в секунду, красная полоса
   UI-потока.
3. Переключатель включён → «Пересчитать»: то же время расчёта, но анимация
   не прерывается, кадры укладываются в 16 мс.
