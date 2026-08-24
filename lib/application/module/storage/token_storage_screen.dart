import 'package:flutter/material.dart';
import 'package:movie_network/movie_network.dart';

import '../../../data/tmdb_config.dart';
import '../../../data/token_storages.dart';
import '../../../dependency_injection/dependency_container/dependency_container.dart';
import '../../../dependency_injection/dependency_container/dependency_scope.dart';
import '../../demo_settings.dart';

/// Демо «Где лежит токен»: одно и то же значение в `SharedPreferences`
/// и в `flutter_secure_storage`.
class TokenStorageScreen extends StatefulWidget {
  const TokenStorageScreen({super.key});

  @override
  State<TokenStorageScreen> createState() => _TokenStorageScreenState();
}

class _TokenStorageScreenState extends State<TokenStorageScreen> {
  late final DependencyContainer _container;

  /// В тестах и в офлайн-режиме в контейнере лежит хранилище попроще —
  /// тогда экрану показывать нечего.
  SwitchableTokenStorage? _storage;

  String? _prefsValue;
  String? _secureValue;
  String? _secureError;
  String? _prefsLocation;

  @override
  void initState() {
    super.initState();
    _container = DependencyScope.of(context);
    final TokenStorage storage = _container.tokenStorage;
    if (storage is SwitchableTokenStorage) {
      _storage = storage;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final SwitchableTokenStorage? storage = _storage;
    if (storage == null) {
      return;
    }

    final ({String? prefs, String? secure, String? secureError}) values =
        await storage.readBothStorages();
    final String location = await storage.prefsStorage.describeLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _prefsValue = values.prefs;
      _secureValue = values.secure;
      _secureError = values.secureError;
      _prefsLocation = location;
    });
  }

  Future<void> _writeToBoth() async {
    await _storage?.writeToBothStorages(TmdbConfig.apiKey);
    await _refresh();
  }

  Future<void> _clearBoth() async {
    await _storage?.prefsStorage.clear();
    await _storage?.secureStorage.clear();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DemoSettings demoSettings = _container.demoSettings;

    if (_storage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Where the token lives')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Демо доступно только в приложении с ключом TMDB: '
              'токена, который стоило бы прятать, здесь просто нет.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Where the token lives')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                onPressed: _writeToBoth,
                child: const Text('Write token to both'),
              ),
              FilledButton.tonal(
                onPressed: _clearBoth,
                child: const Text('Clear both'),
              ),
              OutlinedButton(
                onPressed: _refresh,
                child: const Text('Re-read'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: demoSettings,
            builder: (BuildContext context, Widget? child) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: demoSettings.useSecureStorage,
                onChanged: (bool value) =>
                    demoSettings.useSecureStorage = value,
                title: const Text('App reads the token from secure storage'),
                subtitle: Text(
                  demoSettings.useSecureStorage
                      ? 'Keychain / Keystore'
                      : 'SharedPreferences — plain text on disk',
                  style: theme.textTheme.bodySmall,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _StorageCard(
            title: 'SharedPreferences',
            subtitle: 'Key «${PrefsTokenStorage.key}»',
            value: _prefsValue,
            footer: _prefsLocation == null
                ? null
                : 'File: $_prefsLocation\n'
                      'adb exec-out run-as <applicationId> '
                      'cat shared_prefs/FlutterSharedPreferences.xml',
            isPlainText: true,
          ),
          const SizedBox(height: 12),
          _StorageCard(
            title: 'flutter_secure_storage',
            subtitle: 'Keychain (iOS/macOS) · Keystore (Android)',
            value: _secureError == null
                ? _secureValue
                : 'Недоступно на этой платформе: $_secureError',
            footer:
                'На диске лежит шифртекст; ключ шифрования — в системном '
                'хранилище и не покидает устройство.',
            isPlainText: false,
          ),
          const SizedBox(height: 16),
          Text(
            'Три вещи, без которых защита формальная: отключить autobackup, '
            'чистить deleteAll() при разлогине и не хранить в бинаре то, '
            'что должно жить на сервере — строки в APK и IPA читаются '
            'утилитой strings за секунду.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isPlainText,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String? value;
  final bool isPlainText;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isPlainText ? Icons.lock_open : Icons.lock,
                  color: isPlainText
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SelectableText(
              value ?? '— пусто —',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            if (footer != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(footer!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
