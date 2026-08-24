#!/usr/bin/env bash
#
# Запуск демо к лекции «Асинхронность, сеть и данные».
#
#   ./demo.sh                 — собрать и запустить пример текущей ветки
#   ./demo.sh -d macos        — выбрать устройство (любые флаги уходят в flutter run)
#   ./demo.sh steps           — показать шаги демо этой ветки, ничего не запуская
#   ./demo.sh install         — собрать APK и поставить через adb
#   ./demo.sh link            — отправить диплинк в запущенное приложение (пример 10)
#   ./demo.sh link movie/42   — свой путь вместо movie/278/cast
#
# `install` нужен там, где `flutter run` не видит устройство: некоторые
# прошивки (например, Samsung) не отдают полный `getprop`, и Flutter считает
# телефон неподдерживаемым. Через adb всё ставится и запускается как обычно.
#
# Ключ TMDB берётся из переменной окружения TMDB_API_KEY, а если её нет —
# из конфигурации запуска Android Studio (.run/YaMovies (TMDB).run.xml).
# Самой конфигурации в репозитории нет — только шаблон рядом с ней: скопируйте
# «.run/YaMovies (TMDB).run.xml.template» без расширения .template и подставьте
# свой ключ. Без ключа приложение работает на офлайн-фикстуре.

set -euo pipefail

readonly RUN_CONFIG='.run/YaMovies (TMDB).run.xml'
readonly SCHEME='yamovies'
readonly DEFAULT_LINK='movie/278/cast'

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"

# --- Шаги демо по веткам ------------------------------------------------------
# Тот же текст, что в разделе «Как показывать» в README, — чтобы не искать.
demo_steps() {
  case "$branch" in
    async-01-*)
      cat <<'TXT'
Пример 01 — «UI замирает»
  1. Раскрыть «Lecture demos» на ленте, переключатель изолята выключен.
  2. Нажать «пересчитать»: анимация встаёт, тапы не проходят.
  3. DevTools → Performance: один кадр почти на секунду.
  4. Включить «Compute in a separate isolate» и повторить: кадры на месте.
TXT
      ;;
    async-02-*)
      cat <<'TXT'
Пример 02 — «Три запроса разом»
  1. Открыть фильм: в плашке «3 requests one after another», ~2.4 с.
  2. Внизу экрана включить «Future.wait instead of three awaits».
  3. Кнопка «перезагрузить» в шапке: время падает до самого долгого запроса.
  4. Включить «Break the cast request»: с eagerError экран падает сразу,
     без него — собирается из того, что доехало.
TXT
      ;;
    async-03-*)
      cat <<'TXT'
Пример 03 — избранное как Stream
  1. Добавить фильм в избранное: счётчик в шапке меняется тем же событием.
  2. Открыть фильм, переключить избранное, вернуться: лента уже обновлена.
  3. В логах — «[favorites] появился первый слушатель» и «слушателей не осталось».
TXT
      ;;
    async-04-*)
      cat <<'TXT'
Пример 04 — «Утечка подписки»
  1. «cancel() in dispose» выключен. Зайти на экран фильма и вернуться три раза.
  2. «Live listeners» показывает 3.
  3. Переключить любое избранное: растёт «Calls after dispose», в консоли —
     «событие пришло экрану, которого уже нет».
  4. Включить переключатель, сбросить счётчики, повторить — ноль и тишина.
TXT
      ;;
    async-05-*)
      cat <<'TXT'
Пример 05 — «Строка поиска»
  1. Режим «raw»: набрать «matrix» — в журнале шесть запросов, выдача мигает.
  2. Режим «debounce»: тот же ввод — один запрос.
  3. Режим «switchMap»: у незавершённых запросов статус «cancelled»,
     на экране всегда ответ на последний ввод.
TXT
      ;;
    async-06-*)
      cat <<'TXT'
Пример 06 — «401 и refresh»
  1. Экран «Network: 401 → refresh» в шапке ленты.
  2. «Break token» → «Load feed»: в логе 401, refresh, повтор, данные.
  3. «Break token» → «5 requests at once» с включённой очередью: refresh один.
  4. Выключить очередь и повторить: refresh уходит пять раз.
TXT
      ;;
    async-07-*)
      cat <<'TXT'
Пример 07 — «Где лежит токен»
  1. Экран «Where the token lives», кнопка «Write token to both».
  2. Вытащить XML с эмулятора командой, показанной на экране: токен читается.
  3. Secure storage на том же устройстве — шифртекст, ключ в Keystore/Keychain.
TXT
      ;;
    async-08-*)
      cat <<'TXT'
Пример 08 — кэш на drift
  1. Открыть ленту, затем экран «Local cache»: столько же фильмов, время синка.
  2. Режим полёта (или выключить Wi-Fi) и перезапустить ленту: данные на месте.
  3. «Clear cache» без сети — лента честно показывает ошибку.
TXT
      ;;
    async-09-*)
      cat <<'TXT'
Пример 09 — «Режим полёта»
  1. Включить «Airplane mode»: лента остаётся, сверху баннер «показываем кэш».
  2. Добавить три фильма в избранное: бейджи «не синхронизировано», растёт очередь.
  3. Выключить «Airplane mode»: очередь уходит операция за операцией.
  4. Включить «Server answers 409» и повторить с чётным id: конфликт разрешён
     версией сервера.
TXT
      ;;
    async-10-*)
      cat <<'TXT'
Пример 10 — «Диплинк»
  1. Запустить приложение на Android или iOS: ./demo.sh -d <устройство>
  2. Отправить ссылку: ./demo.sh link
     (то же руками: adb shell am start -a android.intent.action.VIEW \
        -d "yamovies://movie/278/cast")
  3. Кнопка «назад» ведёт на экран фильма, оттуда на ленту — стек восстановлен.
  4. Закрыть приложение полностью и повторить ./demo.sh link — холодный старт.
TXT
      ;;
    *)
      echo "Ветка «$branch» — не пример лекции; шагов демо для неё нет."
      ;;
  esac
}

# --- Ключ TMDB ----------------------------------------------------------------
resolve_api_key() {
  if [[ -n "${TMDB_API_KEY:-}" ]]; then
    printf '%s' "$TMDB_API_KEY"
    return
  fi

  if [[ -f "$RUN_CONFIG" ]]; then
    sed -n 's/.*TMDB_API_KEY=\([^"]*\)".*/\1/p' "$RUN_CONFIG" | head -1
  fi
}

# --- Установка через adb ------------------------------------------------------
install_apk() {
  local api_key
  api_key="$(resolve_api_key)"

  echo "Собираем debug APK…"
  flutter build apk --debug --dart-define=TMDB_API_KEY="$api_key"

  echo "Ставим на устройство…"
  adb install -r build/app/outputs/flutter-apk/app-debug.apk

  echo "Запускаем…"
  adb shell monkey -p com.yandex.yamovies -c android.intent.category.LAUNCHER 1 >/dev/null

  echo
  demo_steps
}

# --- Диплинк ------------------------------------------------------------------
send_link() {
  local path="${1:-$DEFAULT_LINK}"
  local url="$SCHEME://$path"

  case "$branch" in
    async-10-*) ;;
    *)
      echo "Диплинки появляются в примере 10 (ветка async-10-deeplink-go-router)."
      echo "На этой ветке схема «$SCHEME://» ещё не зарегистрирована."
      exit 1
      ;;
  esac

  if command -v adb >/dev/null && [[ -n "$(adb devices | sed -n '2p')" ]]; then
    echo "→ Android: $url"
    local output
    output="$(adb shell am start -a android.intent.action.VIEW -d "$url" 2>&1)"

    if grep -q 'unable to resolve Intent' <<<"$output"; then
      echo "Схему «$SCHEME://» никто не обрабатывает — приложение не установлено."
      echo "Поставьте его: ./demo.sh install"
      exit 1
    fi

    echo "Отправлено. Проверьте «назад»: фильм → лента."
    return
  fi

  if command -v xcrun >/dev/null && xcrun simctl list devices booted | rg -q Booted; then
    echo "→ iOS Simulator: $url"
    xcrun simctl openurl booted "$url"
    echo "Отправлено. Проверьте «назад»: фильм → лента."
    return
  fi

  echo "Не нашёл ни Android-устройства, ни запущенного симулятора iOS."
  echo "Запустите эмулятор и повторите: ./demo.sh link"
  exit 1
}

# --- Разбор аргументов --------------------------------------------------------
case "${1:-run}" in
  steps|--steps|-s)
    demo_steps
    exit 0
    ;;
  install|--install|-i)
    install_apk
    exit 0
    ;;
  link|--link|-l)
    shift || true
    send_link "${1:-}"
    exit 0
    ;;
  help|--help|-h)
    sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

api_key="$(resolve_api_key)"
if [[ -z "$api_key" ]]; then
  echo "TMDB_API_KEY не найден — приложение поднимется на офлайн-фикстуре."
  echo "Передайте ключ: TMDB_API_KEY=<ключ> ./demo.sh"
  echo "Либо создайте конфигурацию из шаблона:"
  echo "  cp '$RUN_CONFIG.template' '$RUN_CONFIG' && \\"
  echo "     sed -i '' 's/ВАШ_КЛЮЧ_TMDB/<ключ>/' '$RUN_CONFIG'"
else
  echo "Ключ TMDB найден, идём в сеть."
fi

echo
demo_steps
echo

exec flutter run --dart-define=TMDB_API_KEY="$api_key" "$@"
