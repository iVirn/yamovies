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
| `async-03-stream-favorites` | 02. Stream | избранное как `StreamController` + `StreamBuilder` |
| `async-04-subscription-leak` | 02. Stream | `listen` без `cancel`: утечка, которую видно на экране |
| `async-05-search-debounce-switchmap` | 03. Трансформации Stream | строка поиска: `debounce`, `switchMap` и отмена запроса |
| `async-06-dio-interceptors-refresh` | 04. Сетевой слой | цепочка интерсепторов, 401 → refresh → повтор, очередь ожидания |
| `async-07-token-storage` | 05. Локальное хранение | `SharedPreferences` против `flutter_secure_storage` |

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

Демо «Три запроса разом». Здесь же приложение впервые выходит в сеть: до этой
ветки оно жило на константной фикстуре.

**Где смотреть в приложении**

Экран фильма: плашка с секундомером под жанрами, ниже — секции «Cast»
и «Similar movies», в самом низу — панель **«Demo: how the screen loads»**
с тремя переключателями. Перезагрузка — кнопка в шапке экрана.

**Файлы**

| Файл | Что в нём |
|---|---|
| `lib/application/module/details/bloc/movie_details_bloc.dart` | Две стратегии загрузки: три `await` подряд или `Future.wait`; замер `Stopwatch`; ветка без `eagerError` собирает частичный результат, потому что `Future.wait` дожидается всех, но всё равно бросает первую ошибку |
| `lib/data/tmdb_api.dart` | DataSource: `topRated`, `genres`, `movieDetails`, `movieCredits`, `similarMovies` |
| `lib/data/movie_repository.dart` | `MovieRepositoryImpl` поверх `TmdbApi`; мок остался как запасной путь и получил задержку — без ожидания демо показывать нечего |
| `lib/data/tmdb_config.dart` | Ключ из `--dart-define`, базовые URL API и картинок, сборка URL постера под размер |
| `lib/domain/movie_details.dart` | `MovieDetails`, `CastMember`, `MovieDetailsBundle` (три ответа плюс время загрузки и частичные ошибки) |
| `lib/domain/movie.dart`, `lib/domain/tmdb_responses.dart` | Разбор JSON руками со значениями по умолчанию; сравнение по значению через `equatable` |
| `lib/utils/error_messages.dart` | `describeLoadError` и `isRetryable`: четыре типа ошибок дают четыре разных сообщения |
| `lib/components/movie_poster.dart` | Постеры по сети: размер под ячейку (`w185`/`w342`/`w500`), `cacheWidth`, фолбэк на локальные ассеты |
| `modules/movie_network/lib/src/http_client.dart`, `network_http_client.dart` | Один `Dio` на приложение, таймауты, `validateStatus`; единственное место, где `DioException` превращается в четыре понятных типа |
| `modules/movie_network/lib/src/api_exception.dart` | `ApiException` — то, что видит приложение вместо ошибок dio |
| `lib/application/module/details/_details_load_timing.dart` | Секундомер экрана и список частичных ошибок |
| `lib/application/module/details/_cast_row.dart`, `_similar_movies_row.dart` | Секции актёров и похожих фильмов |
| `lib/application/module/details/_details_demo_panel.dart` | Переключатели демо и кнопка перезагрузки экрана |
| `lib/application/module/details/_movie_details_view.dart` | Состояние ошибки с кнопкой повтора — и те же переключатели, иначе сломанный запрос уводил бы в тупик |
| `lib/application/module/list/bloc/movie_list_bloc.dart` | Лента и жанры грузятся records `.wait`, `ParallelWaitError` разворачивается в настоящую ошибку |
| `lib/main.dart` | `runZonedGuarded` вокруг `runApp`, выбор репозитория: есть ключ — сеть, нет — фикстура |
| `test/movie_details_bloc_test.dart` | Сумма против максимума, уход с экрана посреди загрузки, маппинг ошибки в состояние |

**Как показывать**

1. Открыть фильм: в плашке — «3 requests one after another», ~2.4 с
   (на фикстуре — ровно 3 × задержку).
2. Внизу экрана включить «Future.wait instead of three awaits», нажать
   «перезагрузить» в шапке: то же самое за время самого долгого запроса.
3. Включить «Break the cast request»: с `eagerError: true` экран падает сразу
   и предлагает повтор; выключить `eagerError` — экран собирается из того,
   что доехало, а ошибка показывается плашкой рядом с секундомером.

## async-03-stream-favorites

Раздел про `Stream`: избранное перестаёт быть полем внутри контроллера
и становится источником, который живёт дольше одного ответа.

**Где смотреть в приложении**

Шапка ленты — счётчик избранного рядом с кнопками; сердечки на карточках;
кнопка избранного на экране фильма. Всё это — подписчики одного потока.
В консоли видно `[favorites] появился первый слушатель` и `слушателей
не осталось`.

**Файлы**

| Файл | Что в нём |
|---|---|
| `lib/data/favorites_service.dart` | `StreamController<Set<int>>.broadcast` с `onListen` / `onCancel`, поток `changes`, поток одного фильма `watchIsFavorite(id)` с `distinct()` и синхронный снимок `current` |
| `lib/application/module/list/_favorites_counter.dart` | Счётчик в шапке — второй подписчик того же потока, ради которого контроллер и сделан `broadcast` |
| `lib/application/module/list/_movie_list_content.dart` | Один `StreamBuilder` на всю сетку (не по одному на карточку) с `initialData: favorites.current` |
| `lib/application/module/list/movie_list_controller.dart` | Больше не хранит `Set<int>`: делегирует сервису и не зовёт `notifyListeners` — перерисовку вызывает событие потока |
| `lib/application/module/details/movie_details_controller.dart` | Вместо копии флага отдаёт `Stream<bool>` и `isFavoriteNow` |
| `lib/application/module/details/_details_favorite_action.dart`, `_details_favorite_button.dart` | Кнопки на `StreamBuilder`: лента и карточка фильма всегда согласованы |
| `lib/application/module/details/movie_details_screen.dart` | Экран больше не принимает `isFavorite` и колбэк — он находит общий источник в контейнере |
| `lib/dependency_injection/dependency_container/dependency_container.dart`, `lib/main.dart` | `FavoritesService` в контейнере, закрывается владельцем |
| `test/widget_test.dart` | Поиск карточек переехал с иконок на tooltip: счётчик в шапке рисует ту же `Icons.favorite` |

**Как показывать**

1. Добавить фильм в избранное на ленте — счётчик в шапке меняется тем же
   событием, не через `setState`.
2. Открыть фильм, нажать «Add to favorites», вернуться назад: лента уже
   перерисована, потому что источник один.
3. В логах — `[favorites] появился первый слушатель` при входе на экран
   и `слушателей не осталось` при выходе: это `onListen` / `onCancel`
   контроллера.

## async-04-subscription-leak

Демо «Утечка подписки». `StreamBuilder` отписывается сам, но ручной `listen`
приходится отменять руками — и цена ошибки здесь вынесена на экран.

**Где смотреть в приложении**

Лента → **«Lecture demos»** → блок **«Subscriptions»**: два счётчика
(«Live listeners» и «Calls after dispose»), кнопка сброса и переключатель
`cancel() in dispose`. Сама подписка живёт на экране фильма — блок
**«Favorite activity»** под кнопкой избранного.

**Файлы**

| Файл | Что в нём |
|---|---|
| `lib/application/module/details/_favorite_activity_log.dart` | Ручная подписка на поток избранного: `listen` в `initState`, отмена в `dispose` — или её отсутствие, в зависимости от переключателя. Здесь же счёт «зомби-вызовов» |
| `lib/application/leak_probe.dart` | Два счётчика: живые подписки и срабатывания колбэка после `dispose`. В настоящем приложении это видно только в DevTools → Memory |
| `lib/application/module/list/_leak_probe_panel.dart` | Счётчики и переключатель на ленте |
| `lib/application/module/list/_demo_panel_section.dart` | Все переключатели ленты собраны в один свёрнутый `ExpansionTile`: демо не должно занимать экран, пока его не показывают |
| `lib/application/module/list/_catalog_stats_panel.dart` | Лишилась собственной карточки — теперь живёт внутри общей секции |
| `lib/application/demo_settings.dart` | Флаг `cancelSubscriptionOnDispose` |

**Как показывать**

1. Переключатель `cancel() in dispose` выключен. Зайти на экран фильма
   и вернуться три раза — «Live listeners» показывает 3.
2. Переключить любое избранное: «Calls after dispose» растёт, а в консоли —
   `setState() called after dispose` и строка
   `событие пришло экрану, которого уже нет`.
3. DevTools → Memory: каждый заход оставил ещё один живой `State`.
4. Включить переключатель, сбросить счётчики, повторить: «Live listeners»
   возвращается к нулю, консоль чистая.

## async-05-search-debounce-switchmap

Демо «Строка поиска»: один экран в трёх режимах, переключается на лету.

**Где смотреть в приложении**

Шапка ленты → кнопка поиска (лупа). На экране поиска: поле ввода,
переключатель режимов `raw / debounce / switchMap`, под ним — **журнал
запросов** со статусами, ниже — выдача. Заголовок выдачи показывает,
**на какой ввод** пришёл ответ.

**Файлы**

| Файл | Что в нём |
|---|---|
| `lib/application/module/search/movie_search_controller.dart` | `BehaviorSubject` для ввода и для выдачи; общий кусок конвейера (`map` → `where` → `distinct`), а различие режимов — ровно в двух операторах: `debounceTime(300ms)` и `switchMap` против `asyncExpand`. Запрос собран на `Stream.multi` ради `onCancel`: `switchMap` отписывается — дёргается `CancelToken` |
| `lib/application/module/search/movie_search_screen.dart` | Экран целиком: поле, режимы, журнал, выдача |
| `lib/application/module/search/_search_field.dart` | Каждый символ уходит в поток; что с ним делать — решают операторы, а не виджет |
| `lib/application/module/search/_search_mode_selector.dart` | `SegmentedButton` с тремя режимами |
| `lib/application/module/search/_search_request_log.dart` | Тот самый Network-таб, только на экране: `in flight` / `done` / `cancelled` / `failed` |
| `lib/application/module/search/_search_results.dart` | Выдача и заголовок «Results for …» |
| `lib/data/tmdb_api.dart`, `lib/data/movie_repository.dart` | `search` с `CancelToken`; мок отвечает тем дольше, чем короче запрос — так воспроизводится гонка ответов |
| `lib/application/module/list/_movie_list_view.dart` | Кнопка поиска в шапке |
| `pubspec.yaml` | Зависимость `rxdart` — ради `BehaviorSubject`, `debounceTime` и `switchMap` |
| `test/movie_search_controller_test.dart` | `fake_async` для debounce (тест на паузу в 300 мс идёт мгновенно), реальное время для `switchMap`, проверка закрытия контроллера посреди запроса |

**Как показывать**

1. Режим `raw`: набрать «matrix» — в журнале шесть запросов, выдача мигает,
   заголовок «Results for…» скачет.
2. Режим `debounce`: тот же ввод — один запрос вместо шести. Если набирать
   с паузами, гонка всё ещё воспроизводится: `asyncExpand` ничего не отменяет.
3. Режим `switchMap`: в журнале видно `cancelled` у незавершённых запросов,
   на экране всегда ответ на последний ввод.

## async-06-dio-interceptors-refresh

Демо «401 и refresh». Токен подменяется на просроченный, TMDB отвечает
настоящим 401 — и дальше всё честно: цепочка интерсепторов обновляет токен
и повторяет запрос, а экран об этом не знает.

> [!NOTE]
> У TMDB v3 нет refresh-флоу: ключ выдаётся в кабинете и не протухает.
> Поэтому «сервер авторизации» заменён на `TmdbAuthService`, который отдаёт
> настоящий ключ после задержки в 700 мс. Всё остальное — 401 от живого
> сервера, очередь ожидающих, повтор запроса, защита от рекурсии — настоящее.
> Задержка тут не для красоты: без неё первый refresh успевает завершиться
> раньше, чем прилетит второй 401, и очередь нечего показывать.

**Где смотреть в приложении**

Шапка ленты → кнопка с иконкой сети → экран **«Network: 401 → refresh»**:
кнопки «Break token», «Restore token», «Load feed», «5 requests at once»,
переключатель очереди, счётчик ушедших refresh и живой лог цепочки.

**Файлы**

| Файл | Что в нём |
|---|---|
| `modules/movie_network/lib/src/interceptors.dart` | `AuthInterceptor` (токен и `extra['startedAt']`), `LoggingInterceptor` (`onRequest` / `onResponse` / `onError` и метрики), `RefreshInterceptor` (401 → refresh → `handler.resolve(retried)`, пометка `retried`, разлогинивание при повторном 401) |
| `modules/movie_network/lib/src/token_refresher.dart` | Очередь ожидания в одну строку: `_inFlight ??= _doRefresh().whenComplete(() => _inFlight = null)`. Флаг `useQueue` выключает её, чтобы показать «стадо 401» |
| `modules/movie_network/lib/src/token_storage.dart` | `TokenStorage` — единственный владелец токена; `InMemoryTokenStorage` на этом шаге |
| `modules/movie_network/lib/src/network_events.dart` | Шина событий сетевого слоя: интерсепторы пишут, экран демо читает |
| `modules/movie_network/lib/src/network_http_client.dart` | Собирает цепочку в порядке регистрации и заводит отдельный «голый» `Dio` для повторов — иначе повтор ушёл бы в рекурсию. `validateStatus` пропускает 4xx, но не 401 |
| `lib/data/tmdb_auth_service.dart` | Заглушка сервера авторизации |
| `lib/application/module/network/network_demo_screen.dart` | Экран демо: кнопки, переключатель очереди, счётчик refresh |
| `lib/application/module/network/_network_event_list.dart` | Лог цепочки: запрос, ошибка, refresh, повтор, ответ |
| `lib/application/module/list/_movie_list_view.dart` | Кнопка сетевого демо в шапке |
| `test/network_interceptors_test.dart` | Семь тестов на подменённом `HttpClientAdapter`: 401 → refresh → повтор, пять 401 против одного refresh, то же без очереди, разлогинивание, 500 → `ApiException`, обрыв → `SocketException`, состав лога |

**Как показывать**

1. «Break token» → «Load feed»: в логе `× movie/top_rated: badResponse 401`,
   затем refresh, повтор и ответ. На экране — данные, пользователь ничего
   не заметил.
2. «Break token» → «5 requests at once» с включённой очередью: пять 401,
   но refresh ушёл **один раз**.
3. Выключить очередь, повторить: refresh уходит пять раз — сервер увидит
   стадо и в реальной системе отзовёт токен.

## async-07-token-storage

Демо «Где лежит токен»: одно и то же значение в двух хранилищах, и разница
видна не в коде, а на диске.

**Добавлено**

- Зависимости `shared_preferences`, `flutter_secure_storage`, `path_provider`.
- `lib/data/token_storages.dart`:
  - `PrefsTokenStorage` на `SharedPreferencesAsync` (без кэша в памяти)
    и метод `describeLocation()` — путь к XML на Android и к plist на iOS;
  - `SecureTokenStorage` на `FlutterSecureStorage` с `deleteAll()` при
    очистке — при разлогине чистим всё, а не один ключ;
  - `SwitchableTokenStorage` — переключается между ними на лету (только ради
    демо; в настоящем приложении владелец токена один) и кэширует значение
    в памяти, потому что интерсептор дёргает токен на каждый запрос.
- `lib/application/module/storage/token_storage_screen.dart` — экран демо:
  записать токен в оба хранилища, перечитать оба, увидеть путь к файлу prefs
  и готовую команду `adb exec-out run-as … cat shared_prefs/…xml`.
- Кнопка «Where the token lives» в шапке ленты.

**Изменено**

- `main.dart` поднимает `WidgetsFlutterBinding` (плагины ходят через каналы
  платформы) и кладёт ключ из сборки в хранилище: дальше сеть берёт токен
  только оттуда — ровно как после логина.
- `DemoSettings.useSecureStorage` решает, какое хранилище считается основным;
  при переключении кэш токена сбрасывается.
- Без ключа TMDB остаётся `InMemoryTokenStorage`, а экран демо честно говорит,
  что прятать нечего.

**Как показывать**

1. «Write token to both» — на экране оба значения видны одинаково.
2. Вытащить XML с эмулятора командой с экрана: токен читается глазами.
3. Файлы secure storage на том же устройстве — шифртекст; ключ лежит
   в Keystore и Keychain и не покидает устройство.
