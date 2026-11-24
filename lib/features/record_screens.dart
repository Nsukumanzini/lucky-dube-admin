// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../data/admin_repository.dart';
import '../data/schemas.dart';
import '../app/localization/app_language.dart';
import '../shared/components/admin_components.dart';
import '../shared/components/premium_surface.dart';

EntityKind? parseKind(String value) {
  final found = EntityKind.values.where((k) => k.name == value);
  return found.isEmpty ? null : found.first;
}

Widget unavailable() => const AdminPage(
    title: 'Record unavailable',
    child: LText('Choose an existing school record from the workspace.'));

class RecordEditor extends ConsumerStatefulWidget {
  final String kind;
  final String? id;
  const RecordEditor({super.key, required this.kind, this.id});
  @override
  ConsumerState<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends ConsumerState<RecordEditor> {
  final form = GlobalKey<FormState>();
  final identifier = TextEditingController();
  final controls = <String, TextEditingController>{};
  EntityKind? kind;
  AdminRecord? original;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    kind = parseKind(widget.kind);
    if (kind == null ||
        [EntityKind.result, EntityKind.resource].contains(kind)) {
      return;
    }
    final r = ref.read(adminRepositoryProvider);
    if (widget.id != null) {
      original = r.find(kind!, widget.id!);
      if (original == null) return;
    }
    identifier.text = widget.id ?? '';
    for (final field in schema(kind!)) {
      var initial = original?[field.key] ?? field.initial;
      if (initial.isEmpty && field.options != null) {
        initial = field.options!.first;
      }
      if (initial.isEmpty && field.reference != null) {
        final options = r
            .records(field.reference!)
            .where((record) => record['status'] != 'Inactive')
            .toList();
        if (options.isNotEmpty) initial = options.first.id;
      }
      controls[field.key] = TextEditingController(text: initial);
    }
  }

  @override
  void dispose() {
    identifier.dispose();
    for (final c in controls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final r = ref.read(adminRepositoryProvider);
    final id = widget.id ??
        (identifier.text.trim().isEmpty
            ? '${kind!.name}-${DateTime.now().microsecondsSinceEpoch}'
            : identifier.text.trim());
    try {
      if (widget.id == null && r.find(kind!, id) != null) {
        throw ArgumentError('This identifier is already in use');
      }
      final record = AdminRecord(id, kind!, {
        ...original?.fields ?? {},
        for (final e in controls.entries) e.key: e.value.text.trim()
      });
      await r.save(record);
      if (mounted) {
        context.replace('/record/${kind!.name}/${Uri.encodeComponent(id)}');
      }
    } on ArgumentError catch (e) {
      if (mounted) setState(() => error = e.message.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(adminRepositoryProvider);
    if (kind == null ||
        controls.isEmpty ||
        (widget.id != null && original == null)) {
      return unavailable();
    }
    return AdminPage(
        title: '${widget.id == null ? 'Create' : 'Edit'} ${labels[kind]}',
        actions: [
          FilledButton.icon(
              onPressed: busy ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: LText(busy ? 'Saving…' : 'Save record'))
        ],
        child: Form(
            key: form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PageHeading(labels[kind]!,
                  'Complete the details below. Changes are stored on this device.'),
              if ([
                EntityKind.learner,
                EntityKind.staff,
                EntityKind.schoolClass,
                EntityKind.subject
              ].contains(kind))
                Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: TextFormField(
                        controller: identifier,
                        readOnly: widget.id != null,
                        decoration: InputDecoration(
                            labelText: tr(context, 'Unique identifier')),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? tr(context, 'Enter an identifier')
                            : null)),
              for (final field in schema(kind!))
                Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Builder(builder: (context) {
                      final controller = controls[field.key]!;
                      final options = field.key == 'audience'
                          ? [
                              'All',
                              'Grade 8',
                              'Grade 9',
                              'Grade 10',
                              ...r
                                  .records(EntityKind.schoolClass)
                                  .map((c) => c.id)
                            ]
                          : field.reference == null
                              ? field.options
                              : r
                                  .records(field.reference!)
                                  .where((record) =>
                                      record['status'] != 'Inactive')
                                  .map((record) => record.id)
                                  .toList();
                      if (options != null) {
                        final valid = options.contains(controller.text)
                            ? controller.text
                            : null;
                        return DropdownButtonFormField<String>(
                            initialValue: valid,
                            isExpanded: true,
                            decoration: InputDecoration(
                                labelText: tr(context, field.label)),
                            items: options
                                .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: LText(
                                        field.reference == null
                                            ? value
                                            : r.label(field.reference!, value),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: busy
                                ? null
                                : (v) {
                                    controller.text = v ?? '';
                                  },
                            validator: (v) =>
                                field.required && (v == null || v.isEmpty)
                                    ? tr(context, 'Choose a value')
                                    : null);
                      }
                      return TextFormField(
                          controller: controller,
                          minLines: field.multiline ? 5 : 1,
                          maxLines: field.multiline ? 12 : 1,
                          decoration: InputDecoration(
                              labelText: tr(context, field.label),
                              alignLabelWithHint: field.multiline),
                          validator: (v) =>
                              field.required && (v == null || v.trim().isEmpty)
                                  ? tr(context, 'Enter a value')
                                  : null);
                    })),
              if (error != null)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xffffeded),
                        borderRadius: BorderRadius.circular(12)),
                    child: LText(error!,
                        style: const TextStyle(color: Color(0xffb91c1c)))),
              const SizedBox(height: 20),
              const LText(
                  'Records in this workspace do not create sign-in accounts in the separate learner or teacher apps.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xff64748b), height: 1.6))
            ])));
  }
}

class RecordDetail extends ConsumerStatefulWidget {
  final String kind, id;
  const RecordDetail({super.key, required this.kind, required this.id});
  @override
  ConsumerState<RecordDetail> createState() => _RecordDetailState();
}

class _RecordDetailState extends ConsumerState<RecordDetail> {
  final reviewNote = TextEditingController();
  String? error;
  @override
  void dispose() {
    reviewNote.dispose();
    super.dispose();
  }

  Future<void> decision(AdminRecord record, String status) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .review(record, status, reviewNote.text);
      if (mounted) {
        setState(() => error = null);
        savedMessage(context, 'Review decision saved on this device');
      }
    } on ArgumentError catch (e) {
      setState(() => error = e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(adminRepositoryProvider);
    final kind = parseKind(widget.kind);
    if (kind == null) return unavailable();
    final record = r.find(kind, widget.id);
    if (record == null) return unavailable();
    final isReview = [EntityKind.result, EntityKind.resource].contains(kind);
    final referenceTypes = {
      'classId': EntityKind.schoolClass,
      'subjectId': EntityKind.subject,
      'teacherId': EntityKind.staff,
      'assignedTo': EntityKind.staff,
      'learnerId': EntityKind.learner,
      'allocationId': EntityKind.allocation
    };
    return AdminPage(
        title: record['name'],
        actions: [
          if (isReview) ...[
            OutlinedButton(
                onPressed: () => decision(record, 'Held'),
                child: const LText('Hold for follow-up')),
            FilledButton(
                onPressed: () => decision(record, 'Published'),
                child: const LText('Approve & publish'))
          ] else ...[
            if (record.active)
              OutlinedButton.icon(
                  onPressed: () => context.push(
                      '/edit/${kind.name}/${Uri.encodeComponent(record.id)}'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const LText('Edit record')),
            if (kind != EntityKind.concern)
              TextButton.icon(
                  onPressed: () async {
                    if (!record.active) {
                      try {
                        await r.save(record.copy({
                          'status': record['previousStatus'].isEmpty
                              ? 'Active'
                              : record['previousStatus']
                        }));
                      } on ArgumentError catch (e) {
                        if (mounted) {
                          setState(() => error = e.message.toString());
                        }
                      }
                      return;
                    }
                    final yes = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                                title: const LText('Archive this record?'),
                                content: const LText(
                                    'Archived records remain available and can be restored. Active links must be removed first.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const LText('Cancel')),
                                  FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const LText('Archive'))
                                ]));
                    if (yes == true) {
                      try {
                        await r.archive(record);
                      } on ArgumentError catch (e) {
                        if (mounted) {
                          setState(() => error = e.message.toString());
                        }
                      }
                    }
                  },
                  icon: Icon(
                      record.active ? Icons.archive_outlined : Icons.restore),
                  label: LText(record.active ? 'Archive' : 'Restore'))
          ]
        ],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeading(record['name'], '${record.id} • ${labels[kind]}'),
          Wrap(spacing: 8, children: [Chip(label: LText(record['status']))]),
          const SizedBox(height: 20),
          Panel(
              'Record details',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final field in record.fields.entries.where((f) =>
                    f.key != 'name' &&
                    f.key != 'status' &&
                    f.key != 'previousStatus'))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LText(fieldLabel(field.key),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff64748b))),
                            const SizedBox(height: 6),
                            SelectableText(
                                referenceTypes.containsKey(field.key)
                                    ? r.label(
                                        referenceTypes[field.key]!, field.value)
                                    : field.value,
                                style: const TextStyle(height: 1.6))
                          ]))
              ])),
          if (kind == EntityKind.schoolClass) ...[
            Panel(
                'Class roster',
                Column(children: [
                  for (final learner in r.roster(record.id))
                    ActionTile(
                        learner['name'],
                        learner.id,
                        Icons.school_outlined,
                        () => context.push('/record/learner/${learner.id}'))
                ])),
            FilledButton.icon(
                onPressed: () => context.push('/register/${record.id}'),
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const LText('Open attendance register'))
          ],
          if (isReview) ...[
            Panel(
                'Review decision',
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (kind == EntityKind.result)
                    const LText(
                        'Marks and educator feedback are read-only. Review controls release status only.'),
                  const SizedBox(height: 14),
                  TextField(
                      controller: reviewNote,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                          labelText: tr(context, 'Review note'),
                          alignLabelWithHint: true)),
                  const SizedBox(height: 14),
                  const LText(
                      'Publishing updates local reports only. No record is sent to another app or school service.',
                      style: TextStyle(fontSize: 12, height: 1.6))
                ]))
          ],
          if (kind == EntityKind.concern)
            const Panel(
                'Learner safety',
                LText(
                    'For real emergencies, contact a responsible adult or emergency service immediately. Case notes here are local and are not delivered to staff.')),
          if (error != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: LText(error!, style: const TextStyle(color: Colors.red)))
        ]));
  }

  String fieldLabel(String key) =>
      {
        'classId': 'Class',
        'grade': 'Grade',
        'guardian': 'Guardian reference',
        'email': 'Email address',
        'speciality': 'Teaching speciality',
        'room': 'Classroom',
        'capacity': 'Capacity',
        'grades': 'Enabled grades',
        'subjectId': 'Subject',
        'teacherId': 'Teacher',
        'allocationId': 'Teaching allocation',
        'day': 'Day',
        'start': 'Start',
        'end': 'End',
        'body': 'Content',
        'audience': 'Audience',
        'priority': 'Priority',
        'date': 'Date',
        'category': 'Category',
        'time': 'Time',
        'venue': 'Venue',
        'assignedTo': 'Assigned staff member',
        'resolution': 'Follow-up / resolution note',
        'learnerId': 'Learner',
        'mark': 'Mark obtained',
        'maxMarks': 'Total marks',
        'feedback': 'Educator feedback',
        'reviewNote': 'Review note'
      }[key] ??
      key;
}

class RegisterScreen extends ConsumerStatefulWidget {
  final String classId;
  const RegisterScreen({super.key, required this.classId});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  String date = '2026-11-26';
  Map<String, String> values = {};
  final reason = TextEditingController();
  String? error;
  bool valid = false;
  @override
  void initState() {
    super.initState();
    final r = ref.read(adminRepositoryProvider);
    valid = r.find(EntityKind.schoolClass, widget.classId)?.active == true;
    if (valid) values = r.attendance(widget.classId, date);
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(adminRepositoryProvider);
    if (!valid) return unavailable();
    return AdminPage(
        title: '${widget.classId} • Attendance register',
        actions: [
          FilledButton.icon(
              onPressed: () async {
                try {
                  await r.saveAttendance(
                      widget.classId, date, values, reason.text);
                  if (context.mounted) {
                    setState(() => error = null);
                    savedMessage(context, 'Attendance correction saved');
                  }
                } on ArgumentError catch (e) {
                  setState(() => error = e.message.toString());
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const LText('Save correction'))
        ],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PageHeading('Attendance register',
              'Corrections require a reason and are recorded in the activity log'),
          OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(date),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2029));
                if (picked != null) {
                  setState(() {
                    date = picked.toIso8601String().substring(0, 10);
                    values = r.attendance(widget.classId, date);
                    reason.clear();
                  });
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(date)),
          const SizedBox(height: 20),
          for (final learner in r.roster(widget.classId))
            LiquidGlassSurface(
                padding: EdgeInsets.zero,
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(learner['name']),
                            Text(learner.id,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xff64748b)))
                          ])),
                      const SizedBox(width: 12),
                      SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                              key: ValueKey('$date-${learner.id}'),
                              initialValue: values[learner.id],
                              isExpanded: true,
                              items: ['Present', 'Absent', 'Late', 'Excused']
                                  .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: LText(s,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => values[learner.id] = v!)))
                    ]))),
          const SizedBox(height: 24),
          TextField(
              controller: reason,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                  labelText: tr(context, 'Reason for correction'),
                  alignLabelWithHint: true)),
          if (error != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: LText(error!, style: const TextStyle(color: Colors.red)))
        ]));
  }
}
