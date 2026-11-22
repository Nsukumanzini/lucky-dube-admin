import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_dube_admin/data/admin_repository.dart';

void main() {
  late LocalAdminRepository r;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    r = LocalAdminRepository(await SharedPreferences.getInstance());
    await r.signIn('A1001', 'Learn123!', true);
  });
  test('administrator sign-in is separate from teacher and learner credentials',
      () async {
    expect(await r.signIn('T1001', 'Learn123!', true), false);
    expect(await r.signIn('A1001', 'incorrect', true), false);
    await r.signOut();
    expect(() => r.records(EntityKind.staff), throwsStateError);
  });
  test('learner grade and class relationships are enforced', () async {
    await expectLater(
        r.save(AdminRecord('LD-new', EntityKind.learner, {
          'name': 'New learner',
          'classId': '8A',
          'grade': '10',
          'status': 'Active'
        })),
        throwsArgumentError);
    await r.save(AdminRecord('LD-new', EntityKind.learner, {
      'name': 'New learner',
      'classId': '8A',
      'grade': '8',
      'status': 'Active'
    }));
    expect(r.roster('8A').length, 10);
  });
  test('duplicate teaching allocations are rejected', () async {
    await expectLater(
        r.save(AdminRecord('duplicate', EntityKind.allocation, {
          'name': 'Duplicate English',
          'classId': '8A',
          'subjectId': 'english',
          'teacherId': 'T1002',
          'status': 'Active'
        })),
        throwsArgumentError);
  });
  test('timetable detects teacher, room and class conflicts', () async {
    await expectLater(
        r.save(AdminRecord('clash', EntityKind.timetable, {
          'name': 'Clash',
          'allocationId': 'alloc-9A',
          'day': 'Thursday',
          'start': '8:30',
          'end': '9:00',
          'room': 'Different room',
          'status': 'Active'
        })),
        throwsArgumentError);
    await r.save(AdminRecord('valid', EntityKind.timetable, {
      'name': 'Later lesson',
      'allocationId': 'alloc-9A',
      'day': 'Friday',
      'start': '8:30',
      'end': '9:00',
      'room': 'B2',
      'status': 'Active'
    }));
    expect(r.find(EntityKind.timetable, 'valid'), isNotNull);
  });
  test('archiving prevents orphaned classes and allocations', () async {
    await expectLater(
        r.archive(r.find(EntityKind.schoolClass, '8A')!), throwsArgumentError);
    await expectLater(r.archive(r.find(EntityKind.allocation, 'alloc-8A')!),
        throwsArgumentError);
  });
  test('staff deactivation cannot leave teaching allocations active', () async {
    await expectLater(
        r.save(r.find(EntityKind.staff, 'T1001')!.copy({'status': 'Inactive'})),
        throwsArgumentError);
  });
  test('results review changes release state without changing marks', () async {
    final result = r.find(EntityKind.result, 'result-1')!;
    await expectLater(r.save(result.copy({'mark': '50'})), throwsStateError);
    await r.review(result, 'Published', 'Checked against the educator record.');
    final saved = r.find(EntityKind.result, result.id)!;
    expect(saved['mark'], result['mark']);
    expect(saved['status'], 'Published');
    expect(r.publishedAverage, 77);
  });
  test('attendance corrections require a reason and persist', () async {
    final values = r.attendance('8A', '2026-11-26');
    values['LD80001'] = 'Late';
    await expectLater(
        r.saveAttendance('8A', '2026-11-26', values, ''), throwsArgumentError);
    await r.saveAttendance(
        '8A', '2026-11-26', values, 'Corrected arrival time');
    expect(
        LocalAdminRepository(r.preferences)
            .attendance('8A', '2026-11-26')['LD80001'],
        'Late');
    expect((r.state['audit'] as List).length, 1);
  });
  test('resolved support cases require a follow-up note', () async {
    final c = r.find(EntityKind.concern, 'concern-1')!;
    await expectLater(
        r.save(c.copy({'status': 'Resolved'})), throwsArgumentError);
    await r.save(c.copy(
        {'status': 'Resolved', 'resolution': 'Follow-up activity recorded.'}));
    expect(r.find(EntityKind.concern, c.id)!['status'], 'Resolved');
  });
  test('academic terms cannot overlap', () async {
    await expectLater(
        r.save(AdminRecord('extra-term', EntityKind.term, {
          'name': 'Overlapping term',
          'start': '2026-11-01',
          'end': '2026-12-01',
          'status': 'Active'
        })),
        throwsArgumentError);
  });
  test('exports include current local enrolment and only published results',
      () {
    expect(r.reportCsv('Enrolment'), contains('LD80001'));
    expect(r.reportCsv('Published results').split('\r\n').length, 2);
  });
  test('reset restores fixtures, retains language and does not sign out',
      () async {
    await r.setLanguage('zu');
    await r.save(r
        .find(EntityKind.staff, 'T1002')!
        .copy({'speciality': 'Updated speciality'}));
    await r.reset();
    expect(r.find(EntityKind.staff, 'T1002')!['speciality'], 'Mathematics');
    expect(r.signedIn, true);
    expect(r.language, 'zu');
    expect(r.state['audit'], null);
  });
  test('new enrolments and other dates stay unrecorded until entered',
      () async {
    await r.save(AdminRecord('new-enrolment', EntityKind.learner, {
      'name': 'New learner',
      'classId': '8A',
      'grade': '8',
      'status': 'Active'
    }));
    expect(
        r.attendance('8A', '2026-11-26').containsKey('new-enrolment'), false);
    expect(r.attendance('8A', '2026-11-27'), isEmpty);
    expect(r.reportCsv('Attendance'), contains('Unrecorded'));
  });
}
