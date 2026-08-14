import 'package:drift/drift.dart';

part 'sqlite_database.dart';

abstract interface class Database {
  const Database();

  static Database create(DatabaseType type, {QueryExecutor? executor}) =>
      switch (type) {
        DatabaseType.sqlite => _SqliteDatabase(executor: executor),
      };
}

enum DatabaseType { sqlite }
