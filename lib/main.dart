// lib/main.dart
// 应用入口

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/widget/widget_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetDataService.init();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
