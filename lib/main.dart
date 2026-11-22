// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/admin_repository.dart';
import 'app/app.dart';

final adminRepositoryProvider = ChangeNotifierProvider<LocalAdminRepository>(
    (ref) => throw StateError('Repository must be supplied'));
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final r = LocalAdminRepository(await SharedPreferences.getInstance());
  if (r.state['remember'] != true) r.state.remove('session');
  runApp(ProviderScope(
      overrides: [adminRepositoryProvider.overrideWith((ref) => r)],
      child: const AdminApp()));
}
