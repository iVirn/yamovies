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

## Модули: где живут сеть и база

Приложение собрано из локальных пакетов — это наследство лекции про
архитектуру. К четвёртой лекции оба были заглушками: `movie_network` знал
только про `Dio`, `movie_database` — только про `drift`. Примеры наполняют
их настоящим кодом, и граница пакета работает как проверка на утечку
абстракции: всё, что выше, про `dio` и строки таблиц уже не знает.

| Пакет | Что в нём появляется | В каком примере |
|---|---|---|
| `modules/movie_network` | `HttpClient` и `HttpClientConfig`, один `Dio` на приложение, таймауты, `ApiException` и превращение `DioException` в четыре понятных типа | 02 |
| | `AuthInterceptor`, `LoggingInterceptor`, `RefreshInterceptor`, `TokenRefresher` с очередью ожидания, `TokenStorage`, шина событий `NetworkEventBus` | 06 |
| `modules/movie_database` | `AppDatabase` на `drift`, таблицы `CachedMovies` / `CachedGenres` / `SyncMeta`, реактивный `watch()`, транзакции и кодогенерация | 08 |
| | Таблицы `FavoriteMovies` и `PendingOps`, `toggleFavoriteWithOutbox` одной транзакцией, чтение очереди по порядку | 09 |

Подключены они как обычные path-зависимости в `pubspec.yaml`, поэтому
`flutter pub get` в корне тянет их сам, а кодогенерация drift запускается
внутри пакета:

```bash
cd modules/movie_database && flutter pub run build_runner build
```

| Ветка | Раздел лекции | Что показывает |
|---|---|---|
| `async-01-event-loop-isolate` | 01. Event loop и Future | тяжёлый расчёт в UI-изоляте против `Isolate.run` |
| `async-02-future-wait` | 01. Event loop и Future | живой TMDB, три запроса экрана фильма через `Future.wait` |

## Запуск

Ключ TMDB передаётся сборкой, а не лежит в коде:

```bash
flutter run --dart-define=TMDB_API_KEY=<ключ>
```

Для Android Studio рядом лежит шаблон конфигурации запуска
`.run/YaMovies (TMDB).run.xml.template`. Скопируйте его без `.template`
и подставьте свой ключ:

```bash
cp '.run/YaMovies (TMDB).run.xml.template' '.run/YaMovies (TMDB).run.xml'
# и заменить ВАШ_КЛЮЧ_TMDB на ключ из кабинета themoviedb.org
```

Готовая конфигурация не отслеживается git — ключ остаётся только у вас.
`demo.sh` берёт ключ оттуда же или из переменной `TMDB_API_KEY`.

> [!NOTE]
> Ключ TMDB — это секрет, и в публичный репозиторий он не попадает.
> Свой можно получить бесплатно: themoviedb.org → Settings → API.

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

## async-02-future-wait

Демо «три запроса разом». Здесь же приложение впервые выходит в сеть: до этой
ветки оно жило на константной фикстуре.

**Добавлено**

- `modules/movie_network` перестал быть заглушкой:
  - `HttpClientConfig` — базовый URL, ключ и таймауты (`connectTimeout`,
    `receiveTimeout`). TMDB понимает оба вида ключей: короткий v3 уходит
    в query-параметр `api_key`, длинный v4 — заголовком `Bearer`.
  - `_NetworkHttpClient` — один `Dio` на приложение с `validateStatus`,
    который отдаёт 4xx нам, а не бросает их сам.
  - `ApiException` и маппинг `DioException` в четыре понятных типа:
    `SocketException`, `TimeoutException`, `FormatException`, `ApiException`.
    Это единственное место, где живёт слово «dio»; выше по слоям про него
    уже никто не знает.
- `lib/data/tmdb_config.dart` — ключ из `--dart-define`, базовые URL API
  и картинок, сборка URL постера под нужный размер.
- `lib/data/tmdb_api.dart` — DataSource: `topRated`, `genres`, `movieDetails`,
  `movieCredits`, `similarMovies`.
- `lib/domain/movie_details.dart` — `MovieDetails`, `CastMember`
  и `MovieDetailsBundle` (три ответа плюс время загрузки и частичные ошибки).
- `Movie.fromJson`, `Genre.fromJson`, `MoviesPageResponse.fromJson` — ручной
  разбор со значениями по умолчанию, как на слайде «Из JSON в модель».
- `lib/utils/error_messages.dart` — `describeLoadError` и `isRetryable`:
  четыре типа ошибок дают четыре разных сообщения и решают, показывать ли
  кнопку «повторить».
- `lib/components/movie_poster.dart` — постеры по сети с `cacheWidth`,
  размером под ячейку (`w185`/`w342`/`w500`) и фолбэком на локальные ассеты
  для шести фильмов из офлайн-фикстуры.
- Экран фильма вырос до трёх секций: детали, актёры (`/credits`)
  и похожие (`/similar`), плюс плашка с секундомером загрузки.

**Изменено**

- `MovieRepository` теперь отдаёт `MovieDetails`, `List<CastMember>`
  и `List<Movie>`; `MovieRepositoryImpl` работает через `TmdbApi`.
- `MovieRepositoryMock` остался как запасной путь без ключа и получил
  искусственную задержку: без ожидания демо «сумма против максимума»
  показывать нечего.
- `MovieDetailsBloc` грузит экран двумя способами — тремя `await` подряд
  или `Future.wait` — и замеряет время `Stopwatch`. Ветка без `eagerError`
  собирает частичный результат: `Future.wait` дожидается всех, но всё равно
  бросает первую ошибку, поэтому ошибку каждого запроса ловим на его
  собственном future.
- `MovieListBloc` грузит ленту и жанры через records `.wait`, разворачивает
  `ParallelWaitError` и умеет состояние ошибки с кнопкой «повторить».
  Хардкодный жанр «Science Fiction» из лекции про состояние убран — жанры
  приходят с сервера.
- `main.dart` — `runZonedGuarded` вокруг `runApp` и выбор репозитория:
  есть ключ — сеть, нет — фикстура.
- `test/widget_test.dart` — тесты поднимают мок с нулевой задержкой
  и ждут первый кадр с данными через `_pumpApp`.

**Как показывать**

1. Открыть фильм: в плашке — «3 requests one after another», ~2.4 с
   (на фикстуре — ровно 3 × задержку).
2. Внизу экрана включить «Future.wait instead of three awaits», нажать
   «перезагрузить» в шапке: то же самое за время самого долгого запроса.
3. Включить «Break the cast request»: с `eagerError: true` экран падает сразу
   и предлагает повтор; выключить `eagerError` — экран собирается из того,
   что доехало, а ошибка показывается плашкой рядом с секундомером.
