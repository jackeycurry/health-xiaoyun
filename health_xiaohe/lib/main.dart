import 'package:flutter/material.dart';
import 'package:health_xiaohe/app.dart';
import 'package:health_xiaohe/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const HealthXiaoheApp());
}
