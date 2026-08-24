import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_network/movie_network.dart';

/// Подменённый адаптер: сеть не нужна, а интерсепторы работают
/// по-настоящему — именно так и проверяют цепочку.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);

  /// Что отвечать по очереди: код и тело.
  final List<({int status, Map<String, Object?> body})> responses;

  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final ({int status, Map<String, Object?> body}) next = responses.isEmpty
        ? (status: 200, body: <String, Object?>{'results': <Object?>[]})
        : responses.removeAt(0);

    return ResponseBody.fromString(
      jsonEncode(next.body),
      next.status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

HttpClient _clientWith(
  _ScriptedAdapter adapter, {
  required TokenStorage storage,
  required TokenRefresher refresher,
  required NetworkEventBus eventBus,
}) {
  final Dio dio = Dio();
  final Dio retryDio = Dio();
  final HttpClient client = HttpClient.create(
    HttpClientType.network,
    config: const HttpClientConfig(baseUrl: 'https://api.themoviedb.org/3/'),
    tokenStorage: storage,
    tokenRefresher: refresher,
    eventBus: eventBus,
    dio: dio,
    retryDio: retryDio,
  );
  // Один и тот же сценарий отвечает и основному клиенту, и клиенту повторов.
  dio.httpClientAdapter = adapter;
  retryDio.httpClientAdapter = adapter;

  return client;
}

void main() {
  late NetworkEventBus eventBus;
  late TokenStorage storage;
  late int refreshCalls;
  late TokenRefresher refresher;

  setUp(() {
    eventBus = NetworkEventBus();
    storage = InMemoryTokenStorage(initialToken: 'expired-token');
    refreshCalls = 0;

    refresher = TokenRefresher(
      storage: storage,
      fetchFreshToken: () {
        refreshCalls++;

        return Future<String?>.delayed(
          const Duration(milliseconds: 50),
          () => 'fresh-token',
        );
      },
      eventBus: eventBus,
    );
  });

  tearDown(() => eventBus.dispose());

  test('401 приводит к refresh и повтору запроса', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<({
      int status,
      Map<String, Object?> body,
    })>[
      (status: 401, body: <String, Object?>{'status_message': 'Invalid token'}),
      (status: 200, body: <String, Object?>{'results': <Object?>[]}),
    ]);

    final Map<String, Object?> json = await _clientWith(
      adapter,
      storage: storage,
      refresher: refresher,
      eventBus: eventBus,
    ).getJson('movie/top_rated');

    expect(json['results'], isEmpty);
    expect(refreshCalls, 1);
    expect(adapter.requests.length, 2, reason: 'исходный запрос и повтор');
    // Повтор ушёл уже со свежим ключом.
    expect(adapter.requests.last.queryParameters['api_key'], 'fresh-token');
    expect(await storage.readAccessToken(), 'fresh-token');
  });

  test('пять одновременных 401 обновляют токен один раз', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<({
      int status,
      Map<String, Object?> body,
    })>[
      for (int i = 0; i < 5; i++)
        (status: 401, body: <String, Object?>{'status_message': 'Invalid'}),
    ]);
    final HttpClient client = _clientWith(
      adapter,
      storage: storage,
      refresher: refresher,
      eventBus: eventBus,
    );

    await Future.wait<Map<String, Object?>>(<Future<Map<String, Object?>>>[
      for (int i = 0; i < 5; i++) client.getJson('movie/$i'),
    ]);

    // Очередь ожидания: refresh уходит один, остальные ждут его future.
    expect(refreshCalls, 1);
  });

  test('без очереди то же стадо даёт пять refresh', () async {
    refresher.useQueue = false;
    final _ScriptedAdapter adapter = _ScriptedAdapter(<({
      int status,
      Map<String, Object?> body,
    })>[
      for (int i = 0; i < 5; i++)
        (status: 401, body: <String, Object?>{'status_message': 'Invalid'}),
    ]);
    final HttpClient client = _clientWith(
      adapter,
      storage: storage,
      refresher: refresher,
      eventBus: eventBus,
    );

    await Future.wait<Map<String, Object?>>(<Future<Map<String, Object?>>>[
      for (int i = 0; i < 5; i++) client.getJson('movie/$i'),
    ]);

    expect(refreshCalls, 5);
  });

  test('повторный 401 после refresh разлогинивает', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(<({
      int status,
      Map<String, Object?> body,
    })>[
      (status: 401, body: <String, Object?>{'status_message': 'Invalid'}),
      (status: 401, body: <String, Object?>{'status_message': 'Still invalid'}),
    ]);

    await expectLater(
      _clientWith(
        adapter,
        storage: storage,
        refresher: refresher,
        eventBus: eventBus,
      ).getJson('movie/top_rated'),
      throwsA(isA<ApiException>()),
    );

    // Защита от рекурсии: второй заход в refresh не делается, токен стёрт.
    expect(refreshCalls, 1);
    expect(await storage.readAccessToken(), isNull);
  });

  test('ошибки сервера превращаются в четыре понятных типа', () async {
    final HttpClient client = _clientWith(
      _ScriptedAdapter(<({int status, Map<String, Object?> body})>[
        (status: 500, body: <String, Object?>{'status_message': 'Server error'}),
      ]),
      storage: storage,
      refresher: refresher,
      eventBus: eventBus,
    );

    await expectLater(
      client.getJson('movie/top_rated'),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.statusCode,
          'statusCode',
          500,
        ),
      ),
    );
  });

  test('обрыв соединения приезжает как SocketException', () async {
    final Dio dio = Dio();
    final HttpClient client = HttpClient.create(
      HttpClientType.network,
      config: const HttpClientConfig(baseUrl: 'https://api.themoviedb.org/3/'),
      tokenStorage: storage,
      tokenRefresher: refresher,
      eventBus: eventBus,
      dio: dio,
    );
    dio.httpClientAdapter = _FailingAdapter();

    await expectLater(
      client.getJson('movie/top_rated'),
      throwsA(isA<SocketException>()),
    );
  });

  test('лог интерсептора видит запрос, ошибку, refresh и повтор', () async {
    final List<NetworkEventKind> kinds = <NetworkEventKind>[];
    eventBus.events.listen((NetworkEvent event) => kinds.add(event.kind));

    await _clientWith(
      _ScriptedAdapter(<({int status, Map<String, Object?> body})>[
        (status: 401, body: <String, Object?>{'status_message': 'Invalid'}),
        (status: 200, body: <String, Object?>{'results': <Object?>[]}),
      ]),
      storage: storage,
      refresher: refresher,
      eventBus: eventBus,
    ).getJson('movie/top_rated');

    await Future<void>.delayed(Duration.zero);

    expect(kinds, contains(NetworkEventKind.request));
    expect(kinds, contains(NetworkEventKind.failure));
    expect(kinds, contains(NetworkEventKind.refreshStarted));
    expect(kinds, contains(NetworkEventKind.retry));
  });
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException.connectionError(
    requestOptions: options,
    reason: 'нет сети',
  );

  @override
  void close({bool force = false}) {}
}
