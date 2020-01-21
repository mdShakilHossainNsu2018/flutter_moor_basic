import 'package:moor/moor.dart';
import 'package:moor_flutter/moor_flutter.dart';

part 'moor_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  // DateTime is not natively supported by SQLite
  // Moor converts it to & from UNIX seconds
  DateTimeColumn get dueDate => dateTime().nullable()();
  // Booleans are not supported as well, Moor converts them to integers
  // Simple default values are specified as Constants
  BoolColumn get completed => boolean().withDefault(Constant(false))();

  @override
  Set<Column> get primaryKey => {id, name};
}

@UseMoor(
  tables: [Tasks],
  daos: [TaskDao],
  queries: {
    // An implementation of this query will be generated inside the _$TaskDaoMixin
    // Both completeTasksGenerated() and watchCompletedTasksGenerated() will be created.
    'completedTasksGenerated':
        'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;'
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super((FlutterQueryExecutor.inDatabaseFolder(
          path: 'db.sqlite',
          // Good for debugging - prints SQL in the console
          logStatements: true,
        )));

  @override
  int get schemaVersion => 1;
}

// Denote which tables this DAO can access
@UseDao(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  final AppDatabase db;

  // Called by the AppDatabase class
  TaskDao(this.db) : super(db);

  Future<List<Task>> getAllTasks() => select(tasks).get();
//  Stream<List<Task>> watchAllTasks() => select(tasks).watch();
  Future insertTask(Insertable<Task> task) => into(tasks).insert(task);
  Future updateTask(Insertable<Task> task) => update(tasks).replace(task);
  Future deleteTask(Insertable<Task> task) => delete(tasks).delete(task);

  // Updated to use the orderBy statement
  Stream<List<Task>> watchAllTasks() {
    // Wrap the whole select statement in parenthesis
    return (select(tasks)
          // Statements like orderBy and where return void => the need to use a cascading ".." operator
          ..orderBy(
            ([
              // Primary sorting by due date
              (t) =>
                  OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
              // Secondary alphabetical sorting
              (t) => OrderingTerm(expression: t.name),
            ]),
          ))
        // watch the whole select statement
        .watch();
  }

  Stream<List<Task>> watchCompletedTasks() {
    // where returns void, need to use the cascading operator
    return (select(tasks)
          ..orderBy(
            ([
              // Primary sorting by due date
              (t) =>
                  OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
              // Secondary alphabetical sorting
              (t) => OrderingTerm(expression: t.name),
            ]),
          )
          ..where((t) => t.completed.equals(true)))
        .watch();
  }

  Stream<List<Task>> watchCompletedTasksCustom() {
    return customSelectStream(
      'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;',
      // The Stream will emit new values when the data inside the Tasks table changes
      readsFrom: {tasks},
    )
        // customSelect or customSelectStream gives us QueryRow list
        // This runs each time the Stream emits a new value.
        .map((rows) {
      // Turning the data of a row into a Task object
      return rows.map((row) => Task.fromData(row.data, db)).toList();
    });
  }
}
