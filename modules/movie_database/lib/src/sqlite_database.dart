part of 'database.dart';

class _SqliteDatabase implements Database {
  _SqliteDatabase({this.executor});

  final QueryExecutor? executor;
}
