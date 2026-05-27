// lib/data/repositories/list_repository.dart
// 清单数据仓库 — Drift 本地持久化 + API 同步

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../local/database.dart';
import '../models/list_model.dart';

final listRepositoryProvider =
    AsyncNotifierProvider<ListRepository, List<ListModel>>(ListRepository.new);

class ListRepository extends AsyncNotifier<List<ListModel>> {
  final _uuid = const Uuid();

  AppDatabase get _db => ref.read(appDatabaseProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<List<ListModel>> build() => _loadFromDb();

  Future<List<ListModel>> _loadFromDb() async {
    final entities = await _db.getAllLists();
    final models = entities.map(ListModel.fromEntity).toList();
    models.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return models;
  }

  Future<void> _notify() async {
    state = AsyncData(await _loadFromDb());
  }

  Future<ListModel?> getListById(String id) async {
    final entity = await _db.getListById(id);
    return entity != null ? ListModel.fromEntity(entity) : null;
  }

  Future<List<ListModel>> get unsyncedLists async {
    final entities = await _db.getUnsyncedLists();
    return entities.map(ListModel.fromEntity).toList();
  }

  Future<void> loadFromServer() async {
    try {
      final response = await _api.getLists();
      if (response.isSuccess && response.data != null) {
        final serverLists =
            response.data!.map((j) => ListModel.fromJson(j)).toList();
        for (final list in serverLists) {
          await _db.insertList(list.toEntity().toCompanion(true));
        }
      }
    } catch (_) {}

    // 确保收集箱存在
    final inbox = await _db.getListById('inbox');
    if (inbox == null) {
      final now = DateTime.now().toUtc();
      await _db.insertList(ListModel(
        id: 'inbox',
        name: '收集箱',
        colorCode: '#4A90D9',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
        syncStatus: 1,
      ).toEntity().toCompanion(true));
    }
    await _notify();
  }

  Future<ListModel> createList({
    required String name,
    String colorCode = '#4A90D9',
    int? sortOrder,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = state.valueOrNull ?? [];
    final list = ListModel(
      id: _uuid.v4(),
      name: name,
      colorCode: colorCode,
      sortOrder: sortOrder ?? existing.length,
      createdAt: now,
      updatedAt: now,
      syncStatus: 0,
    );

    await _db.insertList(list.toEntity().toCompanion(true));
    await _notify();

    try {
      final response = await _api.createList(list.toJson());
      if (response.isSuccess) {
        final synced = list.copyWith(syncStatus: 1);
        await _db.updateList(synced.toEntity().toCompanion(true));
        await _notify();
      }
    } catch (_) {}

    return list;
  }

  Future<ListModel> updateList(ListModel list) async {
    final updated = list.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 0,
    );
    await _db.updateList(updated.toEntity().toCompanion(true));
    await _notify();

    try {
      await _api.updateList(list.id, updated.toJson());
      final synced = updated.copyWith(syncStatus: 1);
      await _db.updateList(synced.toEntity().toCompanion(true));
      await _notify();
    } catch (_) {}

    return updated;
  }

  Future<void> deleteList(String listId) async {
    if (listId == 'inbox') return;
    final now = DateTime.now().toUtc();
    final entity = await _db.getListById(listId);
    if (entity == null) return;
    final list = ListModel.fromEntity(entity);

    final deleted = list.copyWith(
      isDeleted: true,
      updatedAt: now,
      syncStatus: 0,
    );
    await _db.updateList(deleted.toEntity().toCompanion(true));
    await _notify();

    try {
      await _api.deleteList(listId);
    } catch (_) {}
  }

  Future<void> mergeFromServer(List<ListModel> serverLists) async {
    for (final serverList in serverLists) {
      final localEntity = await _db.getListById(serverList.id);
      if (localEntity != null) {
        final local = ListModel.fromEntity(localEntity);
        if (serverList.updatedAt.isAfter(local.updatedAt)) {
          await _db.updateList(serverList.toEntity().toCompanion(true));
        }
      } else {
        await _db.insertList(serverList.toEntity().toCompanion(true));
      }
    }
    await _notify();
  }
}
