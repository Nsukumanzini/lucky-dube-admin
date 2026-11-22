import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EntityKind {
  learner,
  staff,
  schoolClass,
  subject,
  allocation,
  timetable,
  announcement,
  event,
  concern,
  result,
  resource,
  term
}

@immutable
class AdminRecord {
  final String id;
  final EntityKind kind;
  final Map<String, String> fields;
  AdminRecord(this.id, this.kind, Map<String, String> fields)
      : fields = Map.unmodifiable(fields);
  String operator [](String key) => fields[key] ?? '';
  bool get active => this['status'] != 'Archived';
  AdminRecord copy(Map<String, String> changes) =>
      AdminRecord(id, kind, {...fields, ...changes});
  Map<String, dynamic> toJson() =>
      {'id': id, 'kind': kind.name, 'fields': fields};
  factory AdminRecord.fromJson(Map<String, dynamic> j) => AdminRecord(
      j['id'],
      EntityKind.values.byName(j['kind']),
      Map<String, String>.from(j['fields']));
}

abstract class AdminRepository extends ChangeNotifier {
  List<AdminRecord> records(EntityKind kind, {bool includeArchived = false});
  Future<void> save(AdminRecord record);
  Future<void> archive(AdminRecord record);
  Future<bool> signIn(String number, String password, bool remember);
}

class LocalAdminRepository extends AdminRepository {
  final SharedPreferences preferences;
  final Map<String, dynamic> state;
  LocalAdminRepository(this.preferences)
      : state = jsonDecode(preferences.getString('lucky_dube_admin_v1') ?? '{}')
            as Map<String, dynamic>;
  bool get signedIn => state['session'] == 'A1001';
  static const administrator = 'Nomsa Mthembu';
  static const owner = 'Optimal Growth Technologies SA';
  Map<String, String> get school => {
        'name': 'Lucky Dube Secondary School of Performing Arts',
        'displayName': 'Lucky Dube',
        'year': '2026',
        'email': 'office@example.invalid',
        'phone': 'Not configured',
        ...Map<String, String>.from(state['school'] ?? {})
      };
  String get language => state['language'] as String? ?? 'en';
  Future<void> persist() async {
    await preferences.setString('lucky_dube_admin_v1', jsonEncode(state));
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!['en', 'zu'].contains(code)) return;
    state['language'] = code;
    await persist();
  }

  @override
  Future<bool> signIn(String number, String password, bool remember) async {
    if (number.trim().toUpperCase() != 'A1001' || password != 'Learn123!') {
      return false;
    }
    state['session'] = 'A1001';
    state['remember'] = remember;
    await persist();
    return true;
  }

  Future<void> signOut() async {
    state.remove('session');
    await persist();
  }

  void requireSession() {
    if (!signedIn) throw StateError('Administrator sign-in required');
  }

  List<AdminRecord> get seed => [
        for (final c in ['8A', '9A', '10A'])
          AdminRecord(c, EntityKind.schoolClass, {
            'name': 'Grade $c',
            'grade': c.substring(0, c.length - 1),
            'room': c == '10A' ? 'Arts studio' : 'Room B$c',
            'capacity': '35',
            'status': 'Active'
          }),
        for (var i = 0; i < 3; i++)
          AdminRecord('T100${i + 1}', EntityKind.staff, {
            'name': ['Nolwazi Maseko', 'Andile Dlamini', 'Priya Khumalo'][i],
            'email': 'teacher${i + 1}@example.invalid',
            'speciality': ['English', 'Mathematics', 'Creative Arts'][i],
            'status': 'Active'
          }),
        for (final c in ['8A', '9A', '10A'])
          for (var i = 0; i < 9; i++)
            AdminRecord(
                'LD${c == '10A' ? '10' : c[0]}${(i + 1).toString().padLeft(c == '10A' ? 3 : 4, '0')}',
                EntityKind.learner, {
              'name': [
                'Ayanda Mokoena',
                'Lethabo Nkosi',
                'Sipho Dlamini',
                'Zanele Mthembu',
                'Thabo Sithole',
                'Naledi Molefe',
                'Sibusiso Zulu',
                'Anele Jacobs',
                'Bongani Ndlovu'
              ][(i + int.parse(c.substring(0, c.length - 1)) - 8) % 9],
              'classId': c,
              'grade': c.substring(0, c.length - 1),
              'guardian': 'School-held contact',
              'status': 'Active'
            }),
        for (final s in [
          'English',
          'IsiZulu',
          'Mathematics',
          'Natural Sciences',
          'Creative Arts',
          'Life Orientation',
          'Geography',
          'Music',
          'Dramatic Arts'
        ])
          AdminRecord(
              s.replaceAll(' ', '-').toLowerCase(), EntityKind.subject, {
            'name': s,
            'grades': s == 'Natural Sciences'
                ? '8,9'
                : s == 'Music' || s == 'Dramatic Arts' || s == 'Geography'
                    ? '10'
                    : '8,9,10',
            'status': 'Active'
          }),
        for (final c in ['8A', '9A', '10A'])
          AdminRecord('alloc-$c', EntityKind.allocation, {
            'name': 'English • Grade $c',
            'classId': c,
            'subjectId': 'english',
            'teacherId': 'T1001',
            'status': 'Active'
          }),
        for (var i = 0; i < 3; i++)
          AdminRecord('slot-$i', EntityKind.timetable, {
            'name': 'English lesson',
            'allocationId': 'alloc-${['8A', '9A', '10A'][i]}',
            'day': 'Thursday',
            'start': '${8 + i}:15',
            'end': '${9 + i}:00',
            'room': ['B1', 'B2', 'Arts studio'][i],
            'status': 'Active'
          }),
        AdminRecord('notice-1', EntityKind.announcement, {
          'name': 'End-of-year learning arrangements',
          'body':
              'Please follow your class timetable and prepare for the final learning activities. Contact your class teacher for support.',
          'audience': 'All',
          'priority': 'Normal',
          'date': '2026-11-26',
          'status': 'Published'
        }),
        AdminRecord('event-1', EntityKind.event, {
          'name': 'Creative showcase rehearsal',
          'body':
              'Ensemble preparation, sound check and performance readiness.',
          'category': 'Rehearsal',
          'date': '2026-11-26',
          'time': '14:30',
          'venue': 'Arts studio',
          'audience': 'All',
          'status': 'Published'
        }),
        for (var i = 0; i < 3; i++)
          AdminRecord('result-$i', EntityKind.result, {
            'name': 'Term 4 assessment',
            'learnerId': ['LD80001', 'LD90001', 'LD10001'][i],
            'subjectId': 'english',
            'teacherId': 'T1001',
            'mark': '${38 + i}',
            'maxMarks': '50',
            'feedback':
                'Clear reasoning. Show every step to strengthen your explanation.',
            'date': '2026-11-25',
            'status': i == 0 ? 'Published' : 'Pending review',
            'reviewNote': ''
          }),
        AdminRecord('resource-1', EntityKind.resource, {
          'name': 'Original revision guide',
          'body':
              'Read the question carefully, identify what is known, explain your method and check your answer. Original material by Optimal Growth Technologies SA.',
          'teacherId': 'T1001',
          'classId': '8A',
          'date': '2026-11-25',
          'status': 'Pending review',
          'reviewNote': ''
        }),
        AdminRecord('concern-1', EntityKind.concern, {
          'name': 'Classroom learning support request',
          'category': 'Academic concerns',
          'body':
              'A fictional learner has asked for help preparing for revision activities. No real personal information is included.',
          'assignedTo': 'T1001',
          'date': '2026-11-25',
          'status': 'Open',
          'resolution': ''
        }),
        for (var i = 1; i <= 4; i++)
          AdminRecord('term-$i', EntityKind.term, {
            'name': 'Term $i',
            'start': [
              '2026-01-14',
              '2026-04-08',
              '2026-07-21',
              '2026-10-06'
            ][i - 1],
            'end': [
              '2026-03-27',
              '2026-06-26',
              '2026-09-23',
              '2026-12-09'
            ][i - 1],
            'status': 'Active'
          }),
      ];
  List<AdminRecord> get all {
    final saved = List<dynamic>.from(state['records'] ?? [])
        .map((j) => AdminRecord.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    final ids = saved.map((r) => '${r.kind.name}/${r.id}').toSet();
    return [
      ...seed.where((r) => !ids.contains('${r.kind.name}/${r.id}')),
      ...saved
    ];
  }

  @override
  List<AdminRecord> records(EntityKind kind, {bool includeArchived = false}) {
    requireSession();
    return all
        .where((r) => r.kind == kind && (includeArchived || r.active))
        .toList();
  }

  AdminRecord? find(EntityKind kind, String id) {
    requireSession();
    final matches = all.where((r) => r.kind == kind && r.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  void reference(EntityKind kind, String id) {
    if (find(kind, id)?.active != true ||
        find(kind, id)?['status'] == 'Inactive') {
      throw ArgumentError('Choose an active referenced record');
    }
  }

  List<AdminRecord> roster(String classId) => records(EntityKind.learner)
      .where((l) => l['classId'] == classId && l['status'] == 'Active')
      .toList();
  String label(EntityKind kind, String id) => find(kind, id)?['name'] ?? id;
  void audit(String action, String target) {
    final log = List<dynamic>.from(state['audit'] ?? []);
    log.insert(0, {
      'action': action,
      'target': target,
      'actor': administrator,
      'time': DateTime.now().toIso8601String()
    });
    state['audit'] = log;
  }

  @override
  Future<void> save(AdminRecord r) async {
    requireSession();
    if (r.id.trim().isEmpty || r['name'].trim().isEmpty) {
      throw ArgumentError('A name and identifier are required');
    }
    final old = find(r.kind, r.id);
    if (r.kind == EntityKind.result || r.kind == EntityKind.resource) {
      throw StateError('Use the review action for submitted records');
    }
    if (r.kind == EntityKind.learner) {
      reference(EntityKind.schoolClass, r['classId']);
      if (!['8', '9', '10'].contains(r['grade']) ||
          find(EntityKind.schoolClass, r['classId'])!['grade'] != r['grade']) {
        throw ArgumentError('The grade must match the selected class');
      }
      final c = find(EntityKind.schoolClass, r['classId'])!;
      if (r['status'] == 'Active' &&
          roster(r['classId']).where((l) => l.id != r.id).length >=
              int.parse(c['capacity'])) {
        throw ArgumentError('This class is at capacity');
      }
    }
    if (r.kind == EntityKind.staff &&
        (!r['email'].contains('@') || r['speciality'].trim().isEmpty)) {
      throw ArgumentError('Enter valid staff contact information');
    }
    if (r.kind == EntityKind.schoolClass) {
      final capacity = int.tryParse(r['capacity']);
      if (!['8', '9', '10'].contains(r['grade']) ||
          capacity == null ||
          capacity < 1 ||
          capacity < roster(r.id).length) {
        throw ArgumentError('Enter a valid grade and capacity');
      }
      if (old != null &&
          old['grade'] != r['grade'] &&
          roster(r.id).isNotEmpty) {
        throw ArgumentError('A populated class cannot change grade');
      }
    }
    if (r.kind == EntityKind.subject &&
        (!r['grades'].split(',').every(['8', '9', '10'].contains) ||
            r['grades'].isEmpty)) {
      throw ArgumentError('Use enabled grades: 8,9,10');
    }
    if (r.kind == EntityKind.allocation) {
      reference(EntityKind.schoolClass, r['classId']);
      reference(EntityKind.subject, r['subjectId']);
      reference(EntityKind.staff, r['teacherId']);
      if (!find(EntityKind.subject, r['subjectId'])!['grades']
          .split(',')
          .contains(find(EntityKind.schoolClass, r['classId'])!['grade'])) {
        throw ArgumentError('Subject is not enabled for this grade');
      }
      if (records(EntityKind.allocation).any((a) =>
          a.id != r.id &&
          a['classId'] == r['classId'] &&
          a['subjectId'] == r['subjectId'])) {
        throw ArgumentError('This class already has this subject allocation');
      }
    }
    if (r.kind == EntityKind.timetable) {
      reference(EntityKind.allocation, r['allocationId']);
      final start = minutes(r['start']), end = minutes(r['end']);
      if (!['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
              .contains(r['day']) ||
          start == null ||
          end == null ||
          end <= start ||
          r['room'].trim().isEmpty) {
        throw ArgumentError('Enter a valid day, room and time range');
      }
      final allocation = find(EntityKind.allocation, r['allocationId'])!;
      for (final other in records(EntityKind.timetable)
          .where((s) => s.id != r.id && s['day'] == r['day'])) {
        final a = find(EntityKind.allocation, other['allocationId'])!;
        final overlap =
            start < minutes(other['end'])! && end > minutes(other['start'])!;
        if (overlap &&
            (a['classId'] == allocation['classId'] ||
                a['teacherId'] == allocation['teacherId'] ||
                other['room'].trim().toLowerCase() ==
                    r['room'].trim().toLowerCase())) {
          throw ArgumentError(
              'This slot conflicts with a class, teacher or room');
        }
      }
    }
    if (r.kind == EntityKind.announcement || r.kind == EntityKind.event) {
      if (r['body'].trim().isEmpty || DateTime.tryParse(r['date']) == null) {
        throw ArgumentError('Enter content and a valid date');
      }
      if (r['audience'] != 'All' &&
          ![
            'Grade 8',
            'Grade 9',
            'Grade 10',
            ...records(EntityKind.schoolClass).map((c) => c.id)
          ].contains(r['audience'])) {
        throw ArgumentError('Choose a valid audience');
      }
    }
    if (r.kind == EntityKind.term) {
      final start = DateTime.tryParse(r['start']),
          end = DateTime.tryParse(r['end']);
      if (start == null || end == null || !end.isAfter(start)) {
        throw ArgumentError('Enter a valid academic term date range');
      }
      for (final other in records(EntityKind.term).where((t) => t.id != r.id)) {
        if (start.isBefore(DateTime.parse(other['end'])) &&
            end.isAfter(DateTime.parse(other['start']))) {
          throw ArgumentError('Academic terms cannot overlap');
        }
      }
    }
    if (r.kind == EntityKind.concern) {
      reference(EntityKind.staff, r['assignedTo']);
      if (r['status'] == 'Resolved' && r['resolution'].trim().isEmpty) {
        throw ArgumentError('A resolution note is required');
      }
    }
    if (r.kind == EntityKind.staff &&
        r['status'] == 'Inactive' &&
        (records(EntityKind.allocation).any((a) => a['teacherId'] == r.id) ||
            records(EntityKind.concern).any(
                (c) => c['assignedTo'] == r.id && c['status'] != 'Resolved'))) {
      throw ArgumentError(
          'Reassign teaching allocations and open cases before deactivating staff');
    }
    if (r.kind == EntityKind.subject) {
      for (final allocation in records(EntityKind.allocation)
          .where((a) => a['subjectId'] == r.id)) {
        if (!r['grades'].split(',').contains(
            find(EntityKind.schoolClass, allocation['classId'])!['grade'])) {
          throw ArgumentError('An existing allocation requires this grade');
        }
      }
    }
    if (r.kind == EntityKind.allocation) {
      for (final slot in records(EntityKind.timetable)
          .where((s) => s['allocationId'] == r.id)) {
        for (final other in records(EntityKind.timetable)
            .where((s) => s.id != slot.id && s['day'] == slot['day'])) {
          final a = other['allocationId'] == r.id
              ? r
              : find(EntityKind.allocation, other['allocationId'])!;
          if (minutes(slot['start'])! < minutes(other['end'])! &&
              minutes(slot['end'])! > minutes(other['start'])! &&
              (r['classId'] == a['classId'] ||
                  r['teacherId'] == a['teacherId'] ||
                  slot['room'].trim().toLowerCase() ==
                      other['room'].trim().toLowerCase())) {
            throw ArgumentError(
                'This allocation would create a timetable conflict');
          }
        }
      }
    }
    final list = List<dynamic>.from(state['records'] ?? []);
    list.removeWhere((j) => j['kind'] == r.kind.name && j['id'] == r.id);
    list.add(r.toJson());
    state['records'] = list;
    audit(old == null ? 'Created' : 'Updated', '${r.kind.name}/${r.id}');
    await persist();
  }

  static int? minutes(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final h = int.parse(match[1]!), m = int.parse(match[2]!);
    return h > 23 || m > 59 ? null : h * 60 + m;
  }

  @override
  Future<void> archive(AdminRecord r) async {
    requireSession();
    if (!r.active) return;
    final linked = records(EntityKind.allocation).any((a) =>
        (r.kind == EntityKind.staff && a['teacherId'] == r.id) ||
        (r.kind == EntityKind.schoolClass && a['classId'] == r.id) ||
        (r.kind == EntityKind.subject && a['subjectId'] == r.id));
    if (linked ||
        (r.kind == EntityKind.schoolClass && roster(r.id).isNotEmpty) ||
        (r.kind == EntityKind.allocation &&
            records(EntityKind.timetable)
                .any((s) => s['allocationId'] == r.id)) ||
        (r.kind == EntityKind.staff &&
            records(EntityKind.concern).any(
                (c) => c['assignedTo'] == r.id && c['status'] != 'Resolved'))) {
      throw ArgumentError(
          'Remove active allocations and linked records before archiving');
    }
    if (r.kind == EntityKind.result ||
        r.kind == EntityKind.resource ||
        r.kind == EntityKind.concern) {
      throw StateError('Use review and case workflows for this record');
    }
    await save(r.copy({'status': 'Archived', 'previousStatus': r['status']}));
  }

  Future<void> review(AdminRecord r, String status, String note) async {
    requireSession();
    if (![EntityKind.result, EntityKind.resource].contains(r.kind) ||
        !['Published', 'Held'].contains(status) ||
        note.trim().isEmpty ||
        find(r.kind, r.id) == null) {
      throw ArgumentError('A review decision and note are required');
    }
    final current = find(r.kind, r.id)!;
    final updated = current.copy({'status': status, 'reviewNote': note.trim()});
    final list = List<dynamic>.from(state['records'] ?? []);
    list.removeWhere((j) => j['kind'] == r.kind.name && j['id'] == r.id);
    list.add(updated.toJson());
    state['records'] = list;
    audit(status, '${r.kind.name}/${r.id}');
    await persist();
  }

  Map<String, String> attendance(String classId, String date) {
    reference(EntityKind.schoolClass, classId);
    final currentRoster = roster(classId);
    final saved = state['attendance-$classId-$date'];
    if (saved != null) {
      final map = Map<String, String>.from(saved);
      return {
        for (final learner in currentRoster)
          if (map.containsKey(learner.id)) learner.id: map[learner.id]!
      };
    }
    if (date != '2026-11-26') return {};
    final originalIds = seed
        .where((r) => r.kind == EntityKind.learner && r['classId'] == classId)
        .map((r) => r.id)
        .toList();
    return {
      for (final learner in currentRoster)
        if (originalIds.contains(learner.id))
          learner.id:
              originalIds.indexOf(learner.id) == 2 ? 'Absent' : 'Present'
    };
  }

  Future<void> saveAttendance(String classId, String date,
      Map<String, String> values, String reason) async {
    requireSession();
    reference(EntityKind.schoolClass, classId);
    final ids = roster(classId).map((l) => l.id).toSet();
    if (DateTime.tryParse(date) == null ||
        reason.trim().isEmpty ||
        values.length != ids.length ||
        !values.keys.every(ids.contains) ||
        !values.values
            .every(['Present', 'Absent', 'Late', 'Excused'].contains)) {
      throw ArgumentError('Complete the register and give a correction reason');
    }
    state['attendance-$classId-$date'] = values;
    audit('Attendance correction: ${reason.trim()}', '$classId/$date');
    await persist();
  }

  double get publishedAverage {
    final results = records(EntityKind.result)
        .where((r) => r['status'] == 'Published')
        .toList();
    return results.isEmpty
        ? 0
        : results
                .map((r) =>
                    double.parse(r['mark']) / double.parse(r['maxMarks']) * 100)
                .reduce((a, b) => a + b) /
            results.length;
  }

  double attendanceRate(String date) {
    final statuses = <String>[];
    for (final c in records(EntityKind.schoolClass)) {
      final register = attendance(c.id, date);
      statuses.addAll(roster(c.id).map((l) => register[l.id] ?? 'Unrecorded'));
    }
    return statuses.isEmpty
        ? 0
        : statuses.where(['Present', 'Late', 'Excused'].contains).length /
            statuses.length *
            100;
  }

  Future<void> saveSchool(Map<String, String> fields) async {
    requireSession();
    if ((fields['name'] ?? '').trim().isEmpty ||
        (fields['displayName'] ?? '').trim().isEmpty ||
        int.tryParse(fields['year'] ?? '') == null ||
        !(fields['email'] ?? '').contains('@')) {
      throw ArgumentError('Enter valid institution information');
    }
    state['school'] = fields;
    audit('School settings updated', 'school');
    await persist();
  }

  String reportCsv(String type) {
    requireSession();
    final rows = <List<String>>[];
    if (type == 'Enrolment') {
      rows.add(['Learner number', 'Name', 'Class', 'Grade', 'Status']);
      for (final r in records(EntityKind.learner)) {
        rows.add([r.id, r['name'], r['classId'], r['grade'], r['status']]);
      }
    } else if (type == 'Attendance') {
      rows.add(['Class', 'Learner number', 'Date', 'Status']);
      for (final c in records(EntityKind.schoolClass)) {
        final register = attendance(c.id, '2026-11-26');
        for (final learner in roster(c.id)) {
          rows.add([
            c.id,
            learner.id,
            '2026-11-26',
            register[learner.id] ?? 'Unrecorded'
          ]);
        }
      }
    } else {
      rows.add(['Learner', 'Subject', 'Mark', 'Total', 'Status']);
      for (final r in records(EntityKind.result)
          .where((r) => r['status'] == 'Published')) {
        rows.add([
          r['learnerId'],
          label(EntityKind.subject, r['subjectId']),
          r['mark'],
          r['maxMarks'],
          r['status']
        ]);
      }
    }
    String cell(String value) {
      final safe = RegExp(r'^[=+\-@]').hasMatch(value) ? "'$value" : value;
      return '"${safe.replaceAll('"', '""')}"';
    }

    return rows.map((row) => row.map(cell).join(',')).join('\r\n');
  }

  Future<void> reset() async {
    requireSession();
    final languageCode = language;
    state.clear();
    state['session'] = 'A1001';
    state['language'] = languageCode;
    await persist();
  }
}
