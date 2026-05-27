// lib/data/local/database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables.dart';

part 'database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

@DriftDatabase(tables: [Tasks, Lists, Tags, TaskTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ========== Tasks ==========

  Future<List<TaskEntity>> getAllTasks() =>
      (select(tasks)..where((t) => t.isDeleted.equals(false))).get();

  Future<List<TaskEntity>> getAllTasksIncludingDeleted() =>
      select(tasks).get();

  Future<TaskEntity?> getTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TaskEntity>> getUnsyncedTasks() =>
      (select(tasks)..where((t) => t.syncStatus.equals(0))).get();

  Future<int> insertTask(TasksCompanion entry) =>
      into(tasks).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateTask(TasksCompanion entry) =>
      update(tasks).replace(entry);

  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Stream<List<TaskEntity>> watchAllTasks() =>
      (select(tasks)..where((t) => t.isDeleted.equals(false))).watch();

  // ========== Lists ==========

  Future<List<ListEntity>> getAllLists() =>
      (select(lists)..where((l) => l.isDeleted.equals(false))).get();

  Future<List<ListEntity>> getAllListsIncludingDeleted() =>
      select(lists).get();

  Future<ListEntity?> getListById(String id) =>
      (select(lists)..where((l) => l.id.equals(id))).getSingleOrNull();

  Future<List<ListEntity>> getUnsyncedLists() =>
      (select(lists)..where((l) => l.syncStatus.equals(0))).get();

  Future<int> insertList(ListsCompanion entry) =>
      into(lists).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateList(ListsCompanion entry) =>
      update(lists).replace(entry);

  Future<int> deleteList(String id) =>
      (delete(lists)..where((l) => l.id.equals(id))).go();

  Stream<List<ListEntity>> watchAllLists() =>
      (select(lists)..where((l) => l.isDeleted.equals(false))).watch();

  // ========== Tags ==========

  Future<List<TagEntity>> getAllTags() =>
      (select(tags)..where((t) => t.isDeleted.equals(false))).get();

  Future<List<TagEntity>> getAllTagsIncludingDeleted() =>
      select(tags).get();

  Future<TagEntity?> getTagById(String id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TagEntity>> getUnsyncedTags() =>
      (select(tags)..where((t) => t.syncStatus.equals(0))).get();

  Future<int> insertTag(TagsCompanion entry) =>
      into(tags).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateTag(TagsCompanion entry) =>
      update(tags).replace(entry);

  Future<int> deleteTag(String id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  Stream<List<TagEntity>> watchAllTags() =>
      (select(tags)..where((t) => t.isDeleted.equals(false))).watch();

  // ========== TaskTags ==========

  Future<List<TaskTagEntity>> getAllTaskTags() =>
      (select(taskTags)..where((tt) => tt.isDeleted.equals(false))).get();

  Future<List<TaskTagEntity>> getAllTaskTagsIncludingDeleted() =>
      select(taskTags).get();

  Future<List<TaskTagEntity>> getTaskTagsForTask(String taskId) =>
      (select(taskTags)
            ..where((tt) => tt.taskId.equals(taskId) & tt.isDeleted.equals(false)))
          .get();

  Future<int> insertTaskTag(TaskTagsCompanion entry) =>
      into(taskTags).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateTaskTag(TaskTagsCompanion entry) =>
      update(taskTags).replace(entry);

  Future<int> deleteTaskTag(String id) =>
      (delete(taskTags)..where((tt) => tt.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'todo_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
