// ignore_for_file: prefer_initializing_formals

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movie_network/movie_network.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/demo_settings.dart';

/// Токен в настройках.
///
/// На Android это XML в песочнице приложения, на iOS — plist. Ни то,
/// ни другое не зашифровано: на рутованном устройстве, в бэкапе и в отладочной
/// копии данных значение читается глазами.
///
/// ❌ Так делать с токеном нельзя — здесь это сделано, чтобы показать почему.
class PrefsTokenStorage implements TokenStorage {
  PrefsTokenStorage();

  static const String key = 'access_token';

  /// `SharedPreferencesAsync` — без кэша в памяти: каждый вызов идёт
  /// в нативное хранилище.
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> readAccessToken() => _prefs.getString(key);

  @override
  Future<void> writeAccessToken(String token) => _prefs.setString(key, token);

  @override
  Future<void> clear() => _prefs.remove(key);

  /// Где именно лежит файл — то, что показываем на демо.
  Future<String> describeLocation() async {
    if (Platform.isAndroid) {
      return '/data/data/<applicationId>/shared_prefs/'
          'FlutterSharedPreferences.xml';
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final Directory directory = await getLibraryDirectory();

      return '${directory.path}/Preferences/<bundleId>.plist';
    }

    final Directory directory = await getApplicationSupportDirectory();

    return directory.path;
  }
}

/// Токен в защищённом хранилище: Keychain на iOS/macOS, Keystore на Android.
///
/// ✅ Значение шифруется, ключ шифрования лежит в системном хранилище
/// и не покидает устройство.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage();

  static const String key = 'access_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Autobackup выключаем отдельно в манифесте: иначе ключи уедут в облако.
      resetOnError: true,
    ),
  );

  @override
  Future<String?> readAccessToken() => _storage.read(key: key);

  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: key, value: token);

  /// При разлогине чистим всё, а не один ключ.
  @override
  Future<void> clear() => _storage.deleteAll();
}

/// Хранилище, которое переключается на лету — только ради демо.
///
/// В настоящем приложении владелец токена ровно один: два писателя дают
/// гонку за хранилищем, и один экран затрёт токен, обновлённый другим.
class SwitchableTokenStorage implements TokenStorage {
  SwitchableTokenStorage({
    required this.prefsStorage,
    required this.secureStorage,
    required DemoSettings demoSettings,
  }) : _demoSettings = demoSettings {
    // Сменили хранилище — кэш в памяти больше не про него.
    _demoSettings.addListener(_dropCache);
  }

  final PrefsTokenStorage prefsStorage;
  final SecureTokenStorage secureStorage;
  final DemoSettings _demoSettings;

  /// Кэш в памяти: интерсептор дёргает токен на каждый запрос, и ходить
  /// за ним в Keystore каждый раз незачем.
  String? _cachedToken;

  void _dropCache() => _cachedToken = null;

  /// Снять слушателя. Подписка на чужой `ChangeNotifier` — та же утечка,
  /// что и подписка на поток: живёт, пока её не отменят.
  void dispose() => _demoSettings.removeListener(_dropCache);

  TokenStorage get active =>
      _demoSettings.useSecureStorage ? secureStorage : prefsStorage;

  @override
  Future<String?> readAccessToken() async =>
      _cachedToken ??= await active.readAccessToken();

  @override
  Future<void> writeAccessToken(String token) async {
    _cachedToken = token;
    await active.writeAccessToken(token);
  }

  @override
  Future<void> clear() async {
    _cachedToken = null;
    await active.clear();
  }

  /// Демо «где лежит токен»: пишем одно и то же значение в оба хранилища,
  /// чтобы сравнить, что видно снаружи.
  Future<void> writeToBothStorages(String token) async {
    _cachedToken = token;
    await prefsStorage.writeAccessToken(token);

    try {
      await secureStorage.writeAccessToken(token);
    } on PlatformException catch (error) {
      debugPrint('secure storage недоступен на этой платформе: $error');
    }
  }

  /// Что реально лежит в каждом из хранилищ прямо сейчас.
  Future<({String? prefs, String? secure, String? secureError})>
  readBothStorages() async {
    final String? prefsValue = await prefsStorage.readAccessToken();

    try {
      return (
        prefs: prefsValue,
        secure: await secureStorage.readAccessToken(),
        secureError: null,
      );
    } on PlatformException catch (error) {
      return (prefs: prefsValue, secure: null, secureError: error.message);
    } on MissingPluginException catch (error) {
      return (prefs: prefsValue, secure: null, secureError: error.message);
    }
  }
}
