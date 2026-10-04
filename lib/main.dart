import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = await ProgressStore.load();
  runApp(SpatialMemoryApp(progress: progress));
}
