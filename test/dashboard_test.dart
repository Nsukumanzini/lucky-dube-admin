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
import 'package:lucky_dube_admin/shared/components/dashboard_components.dart';

Future<LocalAdminRepository> mount(WidgetTester tester,
    {double width = 1440, double textScale = 1}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final r = LocalAdminRepository(await SharedPreferences.getInstance());
  await r.signIn('A1001', 'Learn123!', true);
  r.state['textScale'] = textScale;
  await tester.pumpWidget(ProviderScope(
      overrides: [adminRepositoryProvider.overrideWith((ref) => r)],
      child: const AdminApp()));
  await tester.pumpAndSettle();
  return r;
}

void main() {
  testWidgets('workspace search opens the matching learner detail screen',
      (tester) async {
    await mount(tester);
    await tester.tap(find.text('Search workspace'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'LD8');
    await tester.pumpAndSettle();
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'LD8');
    await tester.enterText(find.byType(TextField), 'LD80001');
    await tester.pumpAndSettle();
    expect(find.text('2 matching records'), findsOneWidget);
    await tester.tap(find.text('Ayanda Mokoena'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordDetail), findsOneWidget);
    expect(find.text('LD80001 • Learners'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('record directory paginates and search resets its page',
      (tester) async {
    await mount(tester);
    final router = GoRouter.of(tester.element(find.byType(AdminWorkspace)));
    router.go('/learners');
    await tester.pumpAndSettle();
    expect(find.text('1–8 of 27 records'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('9–16 of 27 records'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'LD80001');
    await tester.pumpAndSettle();
    expect(find.text('1–1 of 1 records'), findsOneWidget);
    expect(find.text('Ayanda Mokoena'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('overview metrics update from repository changes',
      (tester) async {
    final r = await mount(tester);
    MetricCard metric() => tester
        .widgetList<MetricCard>(find.byType(MetricCard))
        .firstWhere((x) => x.title == 'Active learners');
    expect(metric().value, '27');
    await r.save(AdminRecord('LD89998', EntityKind.learner, {
      'name': 'New enrolment',
      'grade': '8',
      'classId': '8A',
      'status': 'Active'
    }));
    await tester.pumpAndSettle();
    expect(metric().value, '28');
    expect(r.attendance('8A', '2026-11-26')['LD89998'], isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop overview uses four readable metric columns at 1180',
      (tester) async {
    await mount(tester, width: 1180);
    final cards = find.byType(MetricCard);
    expect(
        tester.getTopLeft(cards.at(0)).dy, tester.getTopLeft(cards.at(3)).dy);
    expect(tester.getTopLeft(cards.at(4)).dy,
        greaterThan(tester.getTopLeft(cards.at(0)).dy));
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile grouped navigation opens the chosen management screen',
      (tester) async {
    await mount(tester, width: 390);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subjects'));
    await tester.pumpAndSettle();
    expect(find.text('Record directory'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1024.0]) {
    testWidgets('dashboard and directory support enlarged text at $width',
        (tester) async {
      await mount(tester, width: width, textScale: 1.4);
      expect(tester.takeException(), isNull);
      final router = GoRouter.of(tester.element(find.byType(AdminWorkspace)));
      for (final page in ['learners', 'results', 'search']) {
        router.go('/$page');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: page);
      }
    });
  }
}
