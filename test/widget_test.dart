// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_dube_admin/main.dart';
import 'package:lucky_dube_admin/app/app.dart';
import 'package:lucky_dube_admin/data/admin_repository.dart';
import 'package:lucky_dube_admin/features/workspace.dart';
import 'package:lucky_dube_admin/features/record_screens.dart';

void main() {
  for (final width in [360.0, 390.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('admin navigation and approval workflows at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final r = LocalAdminRepository(await SharedPreferences.getInstance());
      await r.signIn('A1001', 'Learn123!', true);
      await tester.pumpWidget(ProviderScope(
          overrides: [adminRepositoryProvider.overrideWith((ref) => r)],
          child: const AdminApp()));
      await tester.pumpAndSettle();
      expect(find.text('Your school at a glance'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final router = GoRouter.of(tester.element(find.byType(AdminWorkspace)));
      for (final page in navigation.keys) {
        router.go('/$page');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: page);
      }
      router.push('/new/learner');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'LD89999');
      await tester.enterText(find.byType(TextFormField).at(1), 'New learner');
      await tester.tap(find.text('Save record'));
      await tester.pumpAndSettle();
      expect(r.find(EntityKind.learner, 'LD89999'), isNotNull);
      expect(find.byType(RecordDetail), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();
      router.push('/record/result/result-1');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField), 'Checked and ready for release.');
      await tester.tap(find.text('Approve & publish'));
      await tester.pumpAndSettle();
      expect(r.find(EntityKind.result, 'result-1')!['status'], 'Published');
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();
      router.push('/register/9A');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField), 'Updated from the signed register.');
      await tester.tap(find.text('Save correction'));
      await tester.pumpAndSettle();
      expect(r.state['attendance-9A-2026-11-26'], isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets('isiZulu admin workspace at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final r = LocalAdminRepository(await SharedPreferences.getInstance());
      await r.signIn('A1001', 'Learn123!', true);
      await r.setLanguage('zu');
      await tester.pumpWidget(ProviderScope(
          overrides: [adminRepositoryProvider.overrideWith((ref) => r)],
          child: const AdminApp()));
      await tester.pumpAndSettle();
      expect(find.text('Isikole sakho ngokubuka nje'), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(AdminWorkspace)));
      for (final page in navigation.keys) {
        router.go('/$page');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '$page isiZulu at $width');
      }
      for (final kind in [
        'learner',
        'staff',
        'schoolClass',
        'allocation',
        'timetable',
        'announcement',
        'event',
        'concern',
        'term'
      ]) {
        router.push('/new/$kind');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: kind);
        router.pop();
        await tester.pumpAndSettle();
      }
    });
  }
  testWidgets('sign-in accepts administrators only', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final r = LocalAdminRepository(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
        overrides: [adminRepositoryProvider.overrideWith((ref) => r)],
        child: const AdminApp()));
    await tester.pumpAndSettle();
    expect(find.text('Administrator number'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminWorkspace), findsOneWidget);
  });
}
