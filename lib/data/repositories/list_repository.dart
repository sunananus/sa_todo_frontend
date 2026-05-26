// lib/data/repositories/list_repository.dart
// 清单数据仓库

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../models/list_model.dart';

final listRepositoryProvider =
    NotifierProvider<ListRepository, List<ListModel>>(ListRepository.new);

class ListRepository extends Notifier<List<ListModel>> {
  final _uuid = const Uuid();
  final List<ListModel> _lists = [];

  ApiClient get _api => ref.read(apiClientProvider);

  @override
  List<ListModel> build() => [];

  List<ListModel> get _visibleLists =>
      _lists.where((l) => !l.isDeleted).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _notify() => state = _visibleLists;

  ListModel? getListById(String id) {
    try {
      return _lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ListModel> get unsyncedLists =>
      _lists.where((l) => l.syncStatus == 0).toList();

  Future<void> loadFromServer() async {
    try {
      final response = await _api.getLists();
      if (response.isSuccess && response.data != null) {
        _lists.clear();
        _lists.addAll(response.data!.map((j) => ListModel.fromJson(j)));
      }
    } catch (_) {}

    // 确保收集箱存在
    if (!_lists.any((l) => l.id == 'inbox')) {
      final now = DateTime.now().toUtc();
      _lists.insert(0, ListModel(
        id: 'inbox',
        name: '收集箱',
        colorCode: '#4A90D9',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
        syncStatus: 1,
      ));
    }
    _notify();
  }

  Future<ListModel> createList({
    required String name,
    String colorCode = '#4A90D9',
    int? sortOrder,
  }) async {
    final now = DateTime.now().toUtc();
    final list = ListModel(
      id: _uuid.v4(),
      name: name,
      colorCode: colorCode,
      sortOrder: sortOrder ?? _lists.length,
      createdAt: now,
      updatedAt: now,
      syncStatus: 0,
    );

    _lists.add(list);
    _notify();

    try {
      final response = await _api.createList(list.toJson());
      if (response.isSuccess) {
        final index = _lists.indexWhere((l) => l.id == list.id);
        if (index >= 0) _lists[index] = list.copyWith(syncStatus: 1);
        _notify();
      }
    } catch (_) {}

    return list;
  }

  Future<ListModel> updateList(ListModel list) async {
    final updated = list.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 0,
    );
    final index = _lists.indexWhere((l) => l.id == list.id);
    if (index >= 0) _lists[index] = updated;
    _notify();

    try {
      await _api.updateList(list.id, updated.toJson());
      final idx = _lists.indexWhere((l) => l.id == list.id);
      if (idx >= 0) _lists[idx] = updated.copyWith(syncStatus: 1);
      _notify();
    } catch (_) {}

    return updated;
  }

  Future<void> deleteList(String listId) async {
    if (listId == 'inbox') return; // 不允许删除收集箱
    final now = DateTime.now().toUtc();
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index >= 0) {
      _lists[index] = _lists[index].copyWith(
        isDeleted: true,
        updatedAt: now,
        syncStatus: 0,
      );
    }
    _notify();
    try {
      await _api.deleteList(listId);
    } catch (_) {}
  }

  void mergeFromServer(List<ListModel> serverLists) {
    for (final serverList in serverLists) {
      final index = _lists.indexWhere((l) => l.id == serverList.id);
      if (index >= 0) {
        final local = _lists[index];
        if (serverList.updatedAt.isAfter(local.updatedAt)) {
          _lists[index] = serverList;
        }
      } else {
        _lists.add(serverList);
      }
    }
    _notify();
  }
}
