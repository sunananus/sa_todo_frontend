// lib/main.dart
// 应用入口

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'features/widget/widget_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', '');
  Intl.defaultLocale = 'zh_CN';
  await WidgetDataService.init();
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
