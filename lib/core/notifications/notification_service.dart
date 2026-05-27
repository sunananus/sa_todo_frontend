// lib/core/notifications/notification_service.dart
// 本地通知服务

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  bool get _isSupported => Platform.isIOS || Platform.isAndroid;
  FlutterLocalNotificationsPlugin get _safePlugin {
    _plugin ??= FlutterLocalNotificationsPlugin();
    return _plugin!;
  }

  Future<void> init() async {
    if (_initialized || !_isSupported) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _safePlugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    if (!_isSupported) return;
    await _safePlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// 调度任务提醒通知
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isSupported) return;
    if (!_initialized) await init();

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _safePlugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          '任务提醒',
          channelDescription: '任务到期和提醒通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 取消指定通知
  Future<void> cancel(int id) async {
    if (!_isSupported || !_initialized) return;
    await _safePlugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    if (!_isSupported || !_initialized) return;
    await _safePlugin.cancelAll();
  }
}
