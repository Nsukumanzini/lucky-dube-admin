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
import '../shared/components/admin_shell.dart';
import '../shared/components/dashboard_components.dart';
import '../shared/components/premium_surface.dart';
import 'dashboard/admin_dashboard.dart';

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
    final signInPanel = Panel(
        'Welcome to school administration',
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const LText('A clearer view of your school, together.'),
          const SizedBox(height: 24),
          TextField(
              controller: number,
              decoration: InputDecoration(
                  labelText: tr(context, 'Administrator number'))),
          const SizedBox(height: 16),
          TextField(
              controller: password,
              obscureText: !show,
              decoration: InputDecoration(
                  labelText: tr(context, 'Password'),
                  suffixIcon: IconButton(
                      tooltip: tr(context, 'Show password'),
                      onPressed: () => setState(() => show = !show),
                      icon: Icon(show
                          ? Icons.visibility_off
                          : Icons.visibility_outlined)))),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: remember,
              onChanged: (v) => setState(() => remember = v!),
              title: const LText('Remember me')),
          if (error != null)
            LText(error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
              onPressed: () async {
                final ok = await r.signIn(number.text, password.text, remember);
                if (!ok && mounted) {
                  setState(() =>
                      error = 'Check your administrator number and password.');
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
        ]));
    return Scaffold(
      appBar: AppBar(
          flexibleSpace: const LiquidGlassBar(),
          title: Row(children: [
            Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: blue, borderRadius: BorderRadius.circular(10)),
                child: const Text('LD',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w800))),
            const SizedBox(width: 10),
            const Expanded(
                child: LText('Lucky Dube • Administration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))
          ]),
          actions: const [AdminLanguage()]),
      body: SafeArea(child: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 1000;
        final brand = Container(
            padding: const EdgeInsets.all(42),
            decoration: BoxDecoration(
                color: const Color(0xffe9f1ff),
                border: Border.all(color: const Color(0xffcfdef8)),
                borderRadius: BorderRadius.circular(28)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const LText('SCHOOL ADMINISTRATION',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: blue)),
              const SizedBox(height: 26),
              const LText('A connected school.\nA clearer day.',
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: ink)),
              const SizedBox(height: 20),
              const LText(
                  'Support your people. Organise learning. Keep your school moving forward.',
                  style: TextStyle(
                      fontSize: 15, height: 1.8, color: Color(0xff526783))),
              const SizedBox(height: 26),
              const SizedBox(
                  height: 200, child: Center(child: LearningIllustration())),
              const SizedBox(height: 20),
              const Wrap(spacing: 8, runSpacing: 8, children: [
                StatusPill('People'),
                StatusPill('Learning'),
                StatusPill('School operations')
              ]),
            ]));
        return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 40 : 20),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                Expanded(flex: 6, child: brand),
                                const SizedBox(width: 48),
                                Expanded(flex: 5, child: signInPanel)
                              ])
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: signInPanel)))));
      })),
    );
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
  int pageIndex = 0;
  bool ascending = true;
  String query = '', filter = 'All', report = 'Enrolment';
  LocalAdminRepository get r => ref.read(adminRepositoryProvider);
  void go(String page) {
    setState(() {
      query = '';
      filter = 'All';
      pageIndex = 0;
    });
    context.go('/$page');
  }

  @override
  void didUpdateWidget(covariant AdminWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      query = '';
      filter = 'All';
      pageIndex = 0;
    }
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
    return AdminShell(
        page: widget.page,
        navigation: navigation,
        icon: icon,
        navigate: go,
        repository: r,
        child: content());
  }

  Widget content() {
    if (kinds.containsKey(widget.page)) return registry(kinds[widget.page]!);
    switch (widget.page) {
      case 'home':
        return overview();
      case 'search':
        return workspaceSearch();
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

  Widget overview() => AdminDashboard(repository: r, navigate: go);

  Widget workspaceSearch() {
    final needle = query.trim().toLowerCase();
    final modules = navigation.entries
        .where((e) =>
            tr(context, e.value).toLowerCase().contains(needle) ||
            e.value.toLowerCase().contains(needle))
        .toList();
    final records = needle.isEmpty
        ? <AdminRecord>[]
        : EntityKind.values
            .expand((kind) => r.records(kind))
            .where((x) => '${x.id} ${x.fields.values.join(' ')}'
                .toLowerCase()
                .contains(needle))
            .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeading('Search workspace',
          'Find management areas and school records in one place.'),
      TextField(
          autofocus: true,
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText:
                  tr(context, 'Search people, classes, notices and more')),
          onChanged: (value) => setState(() => query = value)),
      const SizedBox(height: 24),
      DashboardPanel(
          title: 'Management areas',
          subtitle: 'Jump directly to a school workflow',
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in modules)
              ActionChip(
                  avatar: Icon(icon(e.key), size: 17),
                  label: LText(e.value),
                  onPressed: () => go(e.key))
          ])),
      if (needle.isNotEmpty) ...[
        const SizedBox(height: 18),
        DashboardPanel(
            title: 'School records',
            subtitle: '${records.length} matching records',
            child: Column(children: [
              if (records.isEmpty)
                const EmptyPanel('No matching records',
                    'Try a different search or create a record.'),
              for (final item in records.take(40))
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined,
                        size: 20, color: blue),
                    title: Text(item['name'],
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: LText('${labels[item.kind]} • ${item.id}',
                        style: const TextStyle(fontSize: 11, color: muted)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push(
                        '/record/${item.kind.name}/${Uri.encodeComponent(item.id)}')),
              if (records.length > 40)
                const LText('Refine your search to see more specific results.',
                    style: TextStyle(fontSize: 12, color: muted)),
            ])),
      ],
    ]);
  }

  Widget registry(EntityKind kind) {
    final all = r.records(kind, includeArchived: true);
    final visible = all
        .where((record) =>
            (filter == 'All' ? record.active : record['status'] == filter) &&
            ('${record.id} ${record['name']} ${record.fields.values.join(' ')}')
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList()
      ..sort((a, b) => ascending
          ? a['name'].compareTo(b['name'])
          : b['name'].compareTo(a['name']));
    final statuses = [
      'All',
      ...all.map((r) => r['status']).where((s) => s.isNotEmpty).toSet()
    ];
    final pages = (visible.length / 8).ceil().clamp(1, 99999);
    final current = pageIndex.clamp(0, pages - 1);
    final displayed = visible.skip(current * 8).take(8).toList();
    final columns = switch (kind) {
      EntityKind.learner => ('Class', 'Grade'),
      EntityKind.staff => ('Speciality', 'Contact email'),
      EntityKind.schoolClass => ('Grade', 'Classroom'),
      EntityKind.subject => ('Enabled grades', 'Subject'),
      EntityKind.allocation => ('Teacher', 'Class'),
      EntityKind.timetable => ('Day', 'Time'),
      EntityKind.result => ('Learner', 'Mark obtained'),
      EntityKind.resource => ('Teacher', 'Class'),
      EntityKind.announcement => ('Audience', 'Priority'),
      EntityKind.event => ('Date', 'Venue'),
      EntityKind.concern => ('Assigned staff', 'Category'),
      EntityKind.term => ('Start date', 'End date'),
    };
    (String, String) values(AdminRecord x) => switch (kind) {
          EntityKind.learner => (x['classId'], x['grade']),
          EntityKind.staff => (x['speciality'], x['email']),
          EntityKind.schoolClass => (x['grade'], x['room']),
          EntityKind.subject => (x['grades'], x['name']),
          EntityKind.allocation => (
              r.label(EntityKind.staff, x['teacherId']),
              x['classId']
            ),
          EntityKind.timetable => (x['day'], '${x['start']}–${x['end']}'),
          EntityKind.result => (
              r.label(EntityKind.learner, x['learnerId']),
              '${x['mark']}/${x['maxMarks']}'
            ),
          EntityKind.resource => (
              r.label(EntityKind.staff, x['teacherId']),
              x['classId']
            ),
          EntityKind.announcement => (x['audience'], x['priority']),
          EntityKind.event => (x['date'], x['venue']),
          EntityKind.concern => (
              r.label(EntityKind.staff, x['assignedTo']),
              x['category']
            ),
          EntityKind.term => (x['start'], x['end']),
        };
    void open(AdminRecord record) =>
        context.push('/record/${kind.name}/${Uri.encodeComponent(record.id)}');
    Widget identity(AdminRecord x) => Row(children: [
          Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xffedf3ff),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon(widget.page), size: 18, color: blue)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(x['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(x.id, style: const TextStyle(color: muted, fontSize: 10))
              ])),
        ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: PageHeading(labels[kind]!,
                'Manage school records with clear ownership and a local activity trail'))
      ]),
      Wrap(spacing: 10, runSpacing: 10, children: [
        StatusPill('${all.where((x) => x.active).length} records'),
        if (![EntityKind.result, EntityKind.resource].contains(kind))
          FilledButton.icon(
              onPressed: () => context.push('/new/${kind.name}'),
              icon: const Icon(Icons.add, size: 18),
              label: const LText('Create record')),
      ]),
      const SizedBox(height: 20),
      DashboardPanel(
          title: 'Record directory',
          subtitle: 'Search, filter and open a record to manage its details.',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
                key: ValueKey(widget.page),
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: tr(context, 'Search records')),
                onChanged: (v) => setState(() {
                      query = v;
                      pageIndex = 0;
                    })),
            const SizedBox(height: 16),
            Wrap(spacing: 7, runSpacing: 8, children: [
              for (final status in statuses)
                ChoiceChip(
                    label: LText(status),
                    selected: filter == status,
                    onSelected: (_) => setState(() {
                          filter = status;
                          pageIndex = 0;
                        })),
              OutlinedButton.icon(
                  onPressed: () => setState(() {
                        ascending = !ascending;
                        pageIndex = 0;
                      }),
                  icon: Icon(
                      ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16),
                  label: LText(ascending ? 'Name A–Z' : 'Name Z–A',
                      style: const TextStyle(fontSize: 11)))
            ]),
            const SizedBox(height: 18),
            if (displayed.isEmpty)
              const EmptyPanel('No matching records',
                  'Try a different search or create a record.'),
            if (displayed.isNotEmpty)
              LayoutBuilder(builder: (context, box) {
                if (box.maxWidth < 650) {
                  return Column(children: [
                    for (final x in displayed)
                      Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                              border: Border.all(color: line),
                              borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => open(x),
                              child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        identity(x),
                                        const SizedBox(height: 14),
                                        LText(
                                            '${columns.$1}: ${values(x).$1.isEmpty ? '—' : values(x).$1}',
                                            style: const TextStyle(
                                                fontSize: 11, color: muted)),
                                        const SizedBox(height: 10),
                                        Row(children: [
                                          Flexible(
                                              child: StatusPill(x['status'])),
                                          const Spacer(),
                                          const Icon(Icons.arrow_forward,
                                              color: blue, size: 18)
                                        ])
                                      ]))))
                  ]);
                }
                return Column(children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 12),
                      decoration: const BoxDecoration(
                          color: Color(0xfff7f9fc),
                          border: Border(bottom: BorderSide(color: line))),
                      child: Row(children: [
                        for (final col in [
                          ('Record', 5),
                          (columns.$1, 3),
                          (columns.$2, 2),
                          ('Status', 3)
                        ])
                          Expanded(
                              flex: col.$2,
                              child: LText(col.$1,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                      fontWeight: FontWeight.w700))),
                        const SizedBox(width: 32)
                      ])),
                  for (final x in displayed)
                    Container(
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xffedf1f6)))),
                        child: InkWell(
                            onTap: () => open(x),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                child: Row(children: [
                                  Expanded(flex: 5, child: identity(x)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      flex: 3,
                                      child: Text(
                                          values(x).$1.isEmpty
                                              ? '—'
                                              : values(x).$1,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11, color: muted))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          values(x).$2.isEmpty
                                              ? '—'
                                              : values(x).$2,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11, color: muted))),
                                  Expanded(
                                      flex: 3,
                                      child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: StatusPill(x['status']))),
                                  const SizedBox(
                                      width: 32,
                                      child: Icon(Icons.chevron_right,
                                          size: 18, color: blue)),
                                ])))),
                ]);
              }),
            const SizedBox(height: 16),
            Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  LText(
                      '${visible.isEmpty ? 0 : current * 8 + 1}–${(current * 8 + displayed.length)} of ${visible.length} records',
                      style: const TextStyle(fontSize: 11, color: muted)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton.outlined(
                        tooltip: tr(context, 'Previous page'),
                        onPressed: current == 0
                            ? null
                            : () => setState(() => pageIndex = current - 1),
                        icon: const Icon(Icons.chevron_left, size: 18)),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${current + 1} / $pages',
                            style:
                                const TextStyle(fontSize: 11, color: muted))),
                    IconButton.outlined(
                        tooltip: tr(context, 'Next page'),
                        onPressed: current + 1 >= pages
                            ? null
                            : () => setState(() => pageIndex = current + 1),
                        icon: const Icon(Icons.chevron_right, size: 18))
                  ]),
                ]),
          ])),
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
          LiquidGlassSurface(
              padding: EdgeInsets.zero,
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
        LiquidGlassSurface(
            padding: EdgeInsets.zero,
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
        LiquidGlassSurface(
            padding: EdgeInsets.zero,
            child: ActionTile(
                term['name'],
                '${term['start']} — ${term['end']}',
                Icons.date_range,
                () => context.push('/record/term/${term.id}')))
    ]);
  }
}
