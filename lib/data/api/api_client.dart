// lib/data/api/api_client.dart
// Dio HTTP 客户端 — 对接后端 API

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// API 客户端 Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 请求拦截器：动态设置 baseUrl 和 token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final baseUrl =
            prefs.getString(AppConstants.baseUrlKey) ?? AppConstants.defaultBaseUrl;
        final token = prefs.getString(AppConstants.authTokenKey) ?? '';

        options.baseUrl = baseUrl;
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;

  // ========== Task API ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getTasks({String? listId}) async {
    final params = <String, dynamic>{};
    if (listId != null) params['list_id'] = listId;
    final response = await _dio.get('/tasks', queryParameters: params);
    return ApiResponse.fromJson(response.data, asList: true);
  }

  Future<ApiResponse<Map<String, dynamic>>> getTask(String id) async {
    final response = await _dio.get('/tasks/$id');
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<Map<String, dynamic>>> createTask(Map<String, dynamic> data) async {
    final response = await _dio.post('/tasks', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateTask(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/tasks/$id', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<void>> deleteTask(String id) async {
    final response = await _dio.delete('/tasks/$id');
    return ApiResponse.fromJson(response.data);
  }

  // ========== List API ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getLists() async {
    final response = await _dio.get('/lists');
    return ApiResponse.fromJson(response.data, asList: true);
  }

  Future<ApiResponse<Map<String, dynamic>>> createList(Map<String, dynamic> data) async {
    final response = await _dio.post('/lists', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateList(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/lists/$id', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<void>> deleteList(String id) async {
    final response = await _dio.delete('/lists/$id');
    return ApiResponse.fromJson(response.data);
  }

  // ========== Tag API ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getTags() async {
    final response = await _dio.get('/tags');
    return ApiResponse.fromJson(response.data, asList: true);
  }

  Future<ApiResponse<Map<String, dynamic>>> createTag(Map<String, dynamic> data) async {
    final response = await _dio.post('/tags', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateTag(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/tags/$id', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<void>> deleteTag(String id) async {
    final response = await _dio.delete('/tags/$id');
    return ApiResponse.fromJson(response.data);
  }

  // ========== Sync API ==========
  Future<ApiResponse<Map<String, dynamic>>> syncFull(Map<String, dynamic> data) async {
    final response = await _dio.post('/sync/full', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<Map<String, dynamic>>> syncPull(Map<String, dynamic> data) async {
    final response = await _dio.post('/sync/pull', data: data);
    return ApiResponse.fromJson(response.data);
  }

  Future<ApiResponse<Map<String, dynamic>>> syncPush(Map<String, dynamic> data) async {
    final response = await _dio.post('/sync/push', data: data);
    return ApiResponse.fromJson(response.data);
  }

  // ========== Health ==========
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      final data = response.data as Map<String, dynamic>;
      return data['code'] == 0;
    } catch (_) {
      return false;
    }
  }
}

/// 统一响应包装
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  const ApiResponse({required this.code, required this.message, this.data});

  bool get isSuccess => code == 0;

  factory ApiResponse.fromJson(Map<String, dynamic> json, {bool asList = false}) {
    T? data;
    if (json['data'] != null) {
      if (asList) {
        data = (json['data'] as List).cast<Map<String, dynamic>>() as T;
      } else if (json['data'] is Map) {
        data = json['data'] as T;
      }
    }
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: data,
    );
  }
}
