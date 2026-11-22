import 'dart:convert';
import 'dart:typed_data';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import '../data/admin_repository.dart';
import '../data/schemas.dart';
import '../app/localization/app_language.dart';
import '../shared/components/admin_components.dart';
import '../shared/components/learner_visuals.dart';

class AdminLogin extends ConsumerStatefulWidget {
  const AdminLogin({super.key});
  @override
  ConsumerState<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends ConsumerState<AdminLogin> {
  final number = TextEditingController(text: 'A1001'),
      password = TextEditingController(text: 'Learn123!');
  bool show = false, remember = true;
  String? error;
  @override
  void dispose() {
    number.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(adminRepositoryProvider);
    return Scaffold(
        appBar: AppBar(
            title: const LText('Lucky Dube • Administration'),
            actions: const [AdminLanguage()]),
        body: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Panel(
                        'Welcome to school administration',
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const LText(
                                  'A clearer view of your school, together.'),
                              const SizedBox(height: 24),
                              TextField(
                                  controller: number,
                                  decoration: InputDecoration(
                                      labelText:
                                          tr(context, 'Administrator number'))),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: password,
                                  obscureText: !show,
                                  decoration: InputDecoration(
                                      labelText: tr(context, 'Password'),
                                      suffixIcon: IconButton(
                                          tooltip: tr(context, 'Show password'),
                                          onPressed: () =>
                                              setState(() => show = !show),
                                          icon: Icon(show
                                              ? Icons.visibility_off
                                              : Icons.visibility_outlined)))),
                              CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: remember,
                                  onChanged: (v) =>
                                      setState(() => remember = v!),
                                  title: const LText('Remember me')),
                              if (error != null)
                                LText(error!,
                                    style: const TextStyle(color: Colors.red)),
                              FilledButton(
                                  onPressed: () async {
                                    final ok = await r.signIn(
                                        number.text, password.text, remember);
                                    if (!ok && mounted) {
                                      setState(() => error =
                                          'Check your administrator number and password.');
                                    }
                                  },
                                  child: const LText('Sign in')),
                              const SizedBox(height: 24),
                              const LText('Quick access: A1001 • Learn123!'),
                              const SizedBox(height: 16),
                              const LText(
                                  'Administrator accounts are school-managed. Changes in this workspace are saved on this device only.',
                                  style: TextStyle(fontSize: 12, height: 1.6)),
                              const SizedBox(height: 16),
                              const LText(LocalAdminRepository.owner,
                                  style: TextStyle(fontSize: 11))
                            ]))))));
  }
}

const navigation = {
  'home': 'Overview',
  'learners': 'Learners',
  'staff': 'Staff',
  'classes': 'Classes',
  'subjects': 'Subjects',
  'allocations': 'Teaching allocations',
  'timetable': 'Timetable',
  'attendance': 'Attendance',
  'results': 'Results review',
  'resources': 'Resources review',
  'announcements': 'Announcements',
  'calendar': 'School calendar',
  'concerns': 'Support cases',
  'reports': 'Reports',
  'audit': 'Activity log',
  'school': 'School settings',
  'settings': 'Profile & preferences'
};
const kinds = {
  'learners': EntityKind.learner,
  'staff': EntityKind.staff,
  'classes': EntityKind.schoolClass,
  'subjects': EntityKind.subject,
  'allocations': EntityKind.allocation,
  'timetable': EntityKind.timetable,
  'results': EntityKind.result,
  'resources': EntityKind.resource,
  'announcements': EntityKind.announcement,
  'calendar': EntityKind.event,
  'concerns': EntityKind.concern
};

class AdminWorkspace extends ConsumerStatefulWidget {
  final String page;
  const AdminWorkspace({super.key, required this.page});
  @override
  ConsumerState<AdminWorkspace> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends ConsumerState<AdminWorkspace> {
  final shell = GlobalKey<ScaffoldState>();
  String query = '', filter = 'All', report = 'Enrolment';
  LocalAdminRepository get r => ref.read(adminRepositoryProvider);
  void go(String page) {
    setState(() {
      query = '';
      filter = 'All';
    });
    context.go('/$page');
  }

  IconData icon(String page) =>
      {
        'home': Icons.dashboard_outlined,
        'learners': Icons.school_outlined,
        'staff': Icons.badge_outlined,
        'classes': Icons.groups_outlined,
        'subjects': Icons.menu_book_outlined,
        'allocations': Icons.assignment_ind_outlined,
        'timetable': Icons.schedule,
        'attendance': Icons.how_to_reg_outlined,
        'results': Icons.insights_outlined,
        'resources': Icons.folder_outlined,
        'announcements': Icons.campaign_outlined,
        'calendar': Icons.calendar_month_outlined,
        'concerns': Icons.health_and_safety_outlined,
        'reports': Icons.description_outlined,
        'audit': Icons.history,
        'school': Icons.apartment_outlined,
        'settings': Icons.person_outline
      }[page] ??
      Icons.arrow_forward;
  @override
  Widget build(BuildContext context) {
    ref.watch(adminRepositoryProvider);
    if (!r.signedIn) return const SizedBox();
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    Widget menu() => ListView(padding: const EdgeInsets.all(12), children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: LText('SCHOOL WORKSPACE',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5))),
          for (final item in navigation.entries)
            ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: widget.page == item.key,
                selectedTileColor: const Color(0xffeaf3ff),
                selectedColor: const Color(0xff2563eb),
                leading: Icon(icon(item.key), size: 20),
                title: LText(item.value, style: const TextStyle(fontSize: 13)),
                onTap: () {
                  if (!wide) Navigator.pop(context);
                  go(item.key);
                })
        ]);
    return Scaffold(
        key: shell,
        appBar: AppBar(
            title: Row(children: [
              const CircleAvatar(
                  backgroundColor: Color(0xff2563eb),
                  child: Text('LD',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              Expanded(
                  child: LText('${r.school['displayName']} • Administration',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)))
            ]),
            actions: const [AdminLanguage()]),
        drawer: wide ? null : Drawer(child: SafeArea(child: menu())),
        body: Row(children: [
          if (wide) SizedBox(width: 230, child: menu()),
          Expanded(
              child:
                  ListView(padding: EdgeInsets.all(wide ? 32 : 16), children: [
            Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content(),
                          const SizedBox(height: 28),
                          const LText(
                              'Optimal Growth Technologies SA • Information is saved on this device. No changes are sent to school services or the other apps.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff64748b),
                                  height: 1.6))
                        ])))
          ]))
        ]),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: ['home', 'learners', 'timetable', 'concerns']
                        .contains(widget.page)
                    ? ['home', 'learners', 'timetable', 'concerns']
                        .indexOf(widget.page)
                    : 4,
                onDestinationSelected: (i) {
                  if (i == 4) {
                    shell.currentState!.openDrawer();
                  } else {
                    go(['home', 'learners', 'timetable', 'concerns'][i]);
                  }
                },
                destinations: [
                    for (final page in [
                      'home',
                      'learners',
                      'timetable',
                      'concerns',
                      'more'
                    ])
                      NavigationDestination(
                          icon: Icon(page == 'more' ? Icons.menu : icon(page)),
                          label: tr(context,
                              page == 'more' ? 'More' : navigation[page]!))
                  ]));
  }

  Widget content() {
    if (kinds.containsKey(widget.page)) return registry(kinds[widget.page]!);
    switch (widget.page) {
      case 'home':
        return overview();
      case 'attendance':
        return attendance();
      case 'reports':
        return reports();
      case 'audit':
        return audit();
      case 'school':
        return const SchoolSettings();
      case 'settings':
        return preferences();
      default:
        return const PageHeading('Page not found',
            'Use the navigation to return to your workspace.');
    }
  }

  Widget overview() {
    final cards = [
      (
        'Learners',
        '${r.records(EntityKind.learner).where((l) => l['status'] == 'Active').length}',
        'learners',
        Icons.school_outlined
      ),
      (
        'Staff',
        '${r.records(EntityKind.staff).where((s) => s['status'] == 'Active').length}',
        'staff',
        Icons.badge_outlined
      ),
      (
        'Classes',
        '${r.records(EntityKind.schoolClass).length}',
        'classes',
        Icons.groups_outlined
      ),
      (
        'Awaiting review',
        '${r.records(EntityKind.result).where((x) => x['status'] == 'Pending review').length + r.records(EntityKind.resource).where((x) => x['status'] == 'Pending review').length}',
        'results',
        Icons.fact_check_outlined
      )
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeading('Your school at a glance',
          'Thursday, 26 November 2026 • Academic year 2026'),
      WelcomeBanner(onContinue: () => go('school')),
      const SizedBox(height: 20),
      LayoutBuilder(
          builder: (context, b) => Wrap(spacing: 12, runSpacing: 12, children: [
                for (var i = 0; i < cards.length; i++)
                  SizedBox(
                      width: b.maxWidth < 650
                          ? (b.maxWidth - 12) / 2
                          : (b.maxWidth - 36) / 4,
                      child: Card(
                          child: InkWell(
                              onTap: () => go(cards[i].$3),
                              child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(cards[i].$4,
                                            color: learnerAccents[i]),
                                        const SizedBox(height: 14),
                                        LText(cards[i].$1,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xff64748b))),
                                        const SizedBox(height: 10),
                                        Text(cards[i].$2,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800))
                                      ])))))
              ])),
      const SizedBox(height: 22),
      Panel(
          'Today’s priorities',
          Column(children: [
            ActionTile(
                'Review submitted results',
                'Publish or hold with a review note',
                Icons.fact_check_outlined,
                () => go('results')),
            ActionTile(
                'Support cases',
                '${r.records(EntityKind.concern).where((c) => c['status'] != 'Resolved').length} open cases',
                Icons.health_and_safety_outlined,
                () => go('concerns')),
            ActionTile(
                'Attendance overview',
                '${r.attendanceRate('2026-11-26').toStringAsFixed(1)}% present, late or excused',
                Icons.how_to_reg_outlined,
                () => go('attendance'))
          ])),
      Panel(
          'School activity',
          Column(children: [
            for (final event in r
                .records(EntityKind.event)
                .where((e) => e['status'] == 'Published'))
              ActionTile(
                  event['name'],
                  '${event['date']} • ${event['time']} • ${event['venue']}',
                  Icons.event,
                  () => context.push('/record/event/${event.id}'))
          ]))
    ]);
  }

  Widget registry(EntityKind kind) {
    final all = r.records(kind, includeArchived: true);
    final visible = all.where((record) =>
        (filter == 'All' ? record.active : record['status'] == filter) &&
        ('${record.id} ${record['name']} ${record.fields.values.join(' ')}')
            .toLowerCase()
            .contains(query));
    final statuses = [
      'All',
      ...all.map((r) => r['status']).where((s) => s.isNotEmpty).toSet()
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(labels[kind]!,
          'Manage school records with clear ownership and a local activity trail'),
      if (![EntityKind.result, EntityKind.resource].contains(kind))
        FilledButton.icon(
            onPressed: () => context.push('/new/${kind.name}'),
            icon: const Icon(Icons.add),
            label: const LText('Create record')),
      const SizedBox(height: 20),
      TextField(
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr(context, 'Search records')),
          onChanged: (v) => setState(() => query = v.toLowerCase())),
      const SizedBox(height: 14),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses
              .map((status) => ChoiceChip(
                  label: LText(status),
                  selected: filter == status,
                  onSelected: (_) => setState(() => filter = status)))
              .toList()),
      const SizedBox(height: 20),
      if (visible.isEmpty)
        const Panel('No matching records',
            LText('Try a different search or create a record.')),
      for (final record in visible)
        Card(
            child: ActionTile(
                record['name'],
                '${record.id} • ${record['status']}${kind == EntityKind.learner ? ' • ${record['classId']}' : ''}${kind == EntityKind.timetable ? ' • ${record['day']} ${record['start']}–${record['end']}' : ''}',
                icon(widget.page),
                () => context.push(
                    '/record/${kind.name}/${Uri.encodeComponent(record.id)}')))
    ]);
  }

  Widget attendance() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHeading('Attendance oversight',
            'Review class registers and record corrections with a reason'),
        Panel(
            '26 November 2026',
            LText(
                '${r.attendanceRate('2026-11-26').toStringAsFixed(1)}% attendance')),
        for (final c in r.records(EntityKind.schoolClass))
          Card(
              child: ActionTile(
                  c['name'],
                  '${r.roster(c.id).length} active learners • ${r.attendance(c.id, '2026-11-26').values.where((s) => s == 'Absent').length} absent',
                  Icons.how_to_reg_outlined,
                  () => context.push('/register/${c.id}')))
      ]);
  Widget reports() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHeading('Reports & exports',
            'Generate CSV reports from the current local records'),
        Wrap(
            spacing: 8,
            children: ['Enrolment', 'Attendance', 'Published results']
                .map((name) => ChoiceChip(
                    label: LText(name),
                    selected: report == name,
                    onSelected: (_) => setState(() => report = name)))
                .toList()),
        const SizedBox(height: 20),
        Panel(
            'Report preview',
            SelectableText(r.reportCsv(report),
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12, height: 1.6))),
        FilledButton.icon(
            onPressed: () async {
              await FilePicker.platform.saveFile(
                  dialogTitle: tr(context, 'Export report'),
                  fileName:
                      'lucky_dube_${report.replaceAll(' ', '_').toLowerCase()}.csv',
                  bytes: Uint8List.fromList(utf8.encode(r.reportCsv(report))),
                  type: FileType.custom,
                  allowedExtensions: ['csv']);
            },
            icon: const Icon(Icons.download_outlined),
            label: const LText('Export CSV'))
      ]);
  Widget audit() {
    final log = List<dynamic>.from(r.state['audit'] ?? []);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeading('Activity log',
          'Read-only history of changes made in this workspace'),
      if (log.isEmpty)
        const Panel(
            'A clear starting point',
            LText(
                'Saved changes will appear here with an actor and timestamp.')),
      for (final entry in log)
        Card(
            child: ListTile(
                leading: const Icon(Icons.history, color: Color(0xff2563eb)),
                title: LText(entry['action']),
                subtitle: Text(
                    '${entry['target']}\n${entry['actor']} • ${entry['time']}'),
                isThreeLine: true))
    ]);
  }

  Widget preferences() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHeading(
            'Profile & preferences', 'Your administration workspace'),
        const Panel(
            LocalAdminRepository.administrator,
            LText(
                'A1001 • School administrator\nAccount permissions are fixed for this local frontend.')),
        const Panel('Language', AdminLanguage()),
        Panel(
            'Accessibility',
            Column(children: [
              const LText('Text size'),
              Slider(
                  value: (r.state['textScale'] as num?)?.toDouble() ?? 1,
                  min: 1,
                  max: 1.4,
                  divisions: 4,
                  onChanged: (v) {
                    r.state['textScale'] = v;
                    r.persist();
                  })
            ])),
        const Panel(
            'Application information',
            LText(
                'Developed and owned by Optimal Growth Technologies SA. No school endorsement is implied. All profiles and records are fictional. Do not enter sensitive personal information. Changes stay on this device; there is no connection to school services or the separate learner and teacher apps.')),
        OutlinedButton.icon(
            onPressed: () async {
              final yes = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                          title: const LText('Reset local information?'),
                          content: const LText(
                              'This restores the original records and clears changes and the local activity log.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const LText('Cancel')),
                            FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const LText('Reset'))
                          ]));
              if (yes == true) {
                await r.reset();
                if (mounted) savedMessage(context);
              }
            },
            icon: const Icon(Icons.restart_alt),
            label: const LText('Reset local information')),
        const SizedBox(height: 10),
        TextButton.icon(
            onPressed: r.signOut,
            icon: const Icon(Icons.logout),
            label: const LText('Sign out'))
      ]);
}

class SchoolSettings extends ConsumerStatefulWidget {
  const SchoolSettings({super.key});
  @override
  ConsumerState<SchoolSettings> createState() => _SchoolSettingsState();
}

class _SchoolSettingsState extends ConsumerState<SchoolSettings> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> controls;
  String? error;
  @override
  void initState() {
    super.initState();
    controls = {
      for (final e in ref.read(adminRepositoryProvider).school.entries)
        e.key: TextEditingController(text: e.value)
    };
  }

  @override
  void dispose() {
    for (final c in controls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeading('School settings',
          'Institution identity and academic terms • Changes stay on this device'),
      Form(
          key: form,
          child: Panel(
              'Institution information',
              Column(children: [
                for (final field in {
                  'name': 'School name',
                  'displayName': 'Application display name',
                  'year': 'Academic year',
                  'email': 'Contact email',
                  'phone': 'Contact phone'
                }.entries)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                          controller: controls[field.key],
                          decoration: InputDecoration(
                              labelText: tr(context, field.value)),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? tr(context, 'Enter a value')
                              : null)),
                if (error != null)
                  LText(error!, style: const TextStyle(color: Colors.red)),
                FilledButton(
                    onPressed: () async {
                      if (!form.currentState!.validate()) return;
                      try {
                        await ref.read(adminRepositoryProvider).saveSchool({
                          for (final e in controls.entries)
                            e.key: e.value.text.trim()
                        });
                        if (context.mounted) savedMessage(context);
                      } on ArgumentError catch (e) {
                        setState(() => error = e.message.toString());
                      }
                    },
                    child: const LText('Save school settings'))
              ]))),
      const SizedBox(height: 10),
      FilledButton.icon(
          onPressed: () => context.push('/new/term'),
          icon: const Icon(Icons.add),
          label: const LText('Add academic term')),
      const SizedBox(height: 20),
      for (final term
          in ref.watch(adminRepositoryProvider).records(EntityKind.term))
        Card(
            child: ActionTile(
                term['name'],
                '${term['start']} — ${term['end']}',
                Icons.date_range,
                () => context.push('/record/term/${term.id}')))
    ]);
  }
}
