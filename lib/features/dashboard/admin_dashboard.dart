// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/localization/app_language.dart';
import '../../data/admin_repository.dart';
import '../../shared/components/dashboard_components.dart';
import '../../shared/components/admin_components.dart';

/// School-specific adaptation of OG Vibes' metric, shortcut and activity layout.
class AdminDashboard extends StatelessWidget {
  final LocalAdminRepository repository;
  final ValueChanged<String> navigate;
  const AdminDashboard(
      {super.key, required this.repository, required this.navigate});
  @override
  Widget build(BuildContext context) {
    final r = repository;
    final learners = r
        .records(EntityKind.learner)
        .where((x) => x['status'] == 'Active')
        .length;
    final staff = r
        .records(EntityKind.staff)
        .where((x) => x['status'] == 'Active')
        .length;
    final pendingResults = r
        .records(EntityKind.result)
        .where((x) => x['status'] == 'Pending review')
        .length;
    final pendingResources = r
        .records(EntityKind.resource)
        .where((x) => x['status'] == 'Pending review')
        .length;
    final openCases = r
        .records(EntityKind.concern)
        .where((x) => x['status'] != 'Resolved')
        .length;
    final attendance = r.attendanceRate('2026-11-26');
    final cards = [
      (
        'Active learners',
        '$learners',
        'Enrolled in your school',
        'learners',
        Icons.school_outlined,
        blue
      ),
      (
        'Teaching staff',
        '$staff',
        'Active staff records',
        'staff',
        Icons.badge_outlined,
        const Color(0xff0891a3)
      ),
      (
        'School classes',
        '${r.records(EntityKind.schoolClass).length}',
        'Across Grades 8–10',
        'classes',
        Icons.groups_outlined,
        const Color(0xff8055d9)
      ),
      (
        'Attendance today',
        '${attendance.toStringAsFixed(1)}%',
        '26 November • All classes',
        'attendance',
        Icons.how_to_reg_outlined,
        const Color(0xff16804b)
      ),
      (
        'Results to review',
        '$pendingResults',
        'Awaiting a release decision',
        'results',
        Icons.fact_check_outlined,
        const Color(0xffb77a05)
      ),
      (
        'Resources to review',
        '$pendingResources',
        'Learning material submissions',
        'resources',
        Icons.folder_outlined,
        blue
      ),
      (
        'Open support cases',
        '$openCases',
        'Assigned school follow-up',
        'concerns',
        Icons.health_and_safety_outlined,
        const Color(0xffbe3346)
      ),
      (
        'Published notices',
        '${r.records(EntityKind.announcement).where((x) => x['status'] == 'Published').length}',
        'School communication',
        'announcements',
        Icons.campaign_outlined,
        const Color(0xff0891a3)
      ),
    ];
    final log = List<Map<String, dynamic>>.from(
        (r.state['audit'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e)));
    final queue = [
      ...r.records(EntityKind.result),
      ...r.records(EntityKind.resource)
    ].where((x) => x['status'] == 'Pending review').toList();
    return DashboardReveal(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Expanded(
            child: PageHeading('Your school at a glance',
                'A clearer view of your people, learning and school operations.')),
        IconButton.outlined(
            tooltip: tr(context, 'Refresh overview'),
            onPressed: () async {
              await r.persist();
              if (context.mounted) savedMessage(context, 'Overview updated');
            },
            icon: const Icon(Icons.refresh, size: 20)),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: [
        const StatusPill('Term 4'),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(20)),
            child: LText('26 November 2026 • Academic year ${r.school['year']}',
                style: const TextStyle(fontSize: 11, color: muted))),
      ]),
      const SizedBox(height: 22),
      LayoutBuilder(builder: (context, box) {
        final count = box.maxWidth >= 800 ? 4 : 2;
        return Wrap(spacing: 14, runSpacing: 14, children: [
          for (final c in cards)
            SizedBox(
                width: (box.maxWidth - 14 * (count - 1)) / count,
                child: MetricCard(
                    title: c.$1,
                    value: c.$2,
                    note: c.$3,
                    icon: c.$5,
                    color: c.$6,
                    onTap: () => navigate(c.$4)))
        ]);
      }),
      const SizedBox(height: 22),
      DashboardColumns(
        leftFlex: 5,
        rightFlex: 4,
        left: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
                color: const Color(0xffe6efff),
                border: Border.all(color: const Color(0xffcbddfc)),
                borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.campaign_outlined, color: blue),
                SizedBox(width: 10),
                Expanded(
                    child: LText('COMMUNICATION CENTRE',
                        style: TextStyle(
                            fontSize: 10,
                            color: blue,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3)))
              ]),
              const SizedBox(height: 20),
              const LText('Keep your school\nin the loop.',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: ink)),
              const SizedBox(height: 12),
              const LText(
                  'Organise clear notices for the right classes and grades, all in one place.',
                  style: TextStyle(
                      fontSize: 13, height: 1.7, color: Color(0xff526783))),
              const SizedBox(height: 22),
              FilledButton.icon(
                  onPressed: () => navigate('announcements'),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const LText('Open announcements')),
            ])),
        right: DashboardPanel(
            title: 'Quick actions',
            subtitle: 'Your everyday administration tools',
            child: LayoutBuilder(
                builder: (context, box) =>
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final action in [
                        (
                          'Add learner',
                          Icons.person_add_outlined,
                          '/new/learner'
                        ),
                        (
                          'Create notice',
                          Icons.edit_note_outlined,
                          '/new/announcement'
                        ),
                        ('Plan an event', Icons.event_outlined, '/new/event'),
                        ('Export reports', Icons.download_outlined, '/reports')
                      ])
                        SizedBox(
                            width: box.maxWidth < 300
                                ? box.maxWidth
                                : (box.maxWidth - 10) / 2,
                            child: OutlinedButton(
                                onPressed: () => context.push(action.$3),
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                    backgroundColor: const Color(0xfff8fafd),
                                    alignment: Alignment.centerLeft),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(action.$2, size: 21),
                                      const SizedBox(height: 12),
                                      LText(action.$1,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700))
                                    ]))),
                    ]))),
      ),
      const SizedBox(height: 18),
      DashboardColumns(
          left: DashboardPanel(
              title: 'Attendance by class',
              subtitle: 'Present, late or excused • 26 November',
              action: 'View registers',
              onAction: () => navigate('attendance'),
              child: Column(children: [
                for (final c in r.records(EntityKind.schoolClass))
                  Builder(builder: (context) {
                    final roster = r.roster(c.id);
                    final values = r.attendance(c.id, '2026-11-26');
                    final attended = roster
                        .where((x) => ['Present', 'Late', 'Excused']
                            .contains(values[x.id]))
                        .length;
                    final rate =
                        roster.isEmpty ? 0.0 : attended / roster.length;
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(children: [
                          Row(children: [
                            Expanded(
                                child: Text(c['name'],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700))),
                            Text(
                                '$attended/${roster.length} • ${(rate * 100).toStringAsFixed(0)}%',
                                style:
                                    const TextStyle(fontSize: 12, color: muted))
                          ]),
                          const SizedBox(height: 10),
                          Semantics(
                              label:
                                  '${c['name']}: ${(rate * 100).toStringAsFixed(0)}%',
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                      value: rate,
                                      minHeight: 8,
                                      color: const Color(0xff0891a3),
                                      backgroundColor:
                                          const Color(0xffeaf0f6)))),
                        ]));
                  }),
              ])),
          right: DashboardPanel(
              title: 'Review queue',
              subtitle: 'Submitted work awaiting your decision',
              action: 'View all',
              onAction: () => navigate('results'),
              child: Column(children: [
                if (queue.isEmpty)
                  const EmptyPanel(
                      'All caught up', 'New submissions will appear here.'),
                for (final item in queue.take(3))
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: const Color(0xfffff4df),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(
                              item.kind == EntityKind.result
                                  ? Icons.fact_check_outlined
                                  : Icons.folder_outlined,
                              size: 19,
                              color: const Color(0xffa06c08))),
                      title: Text(item['name'],
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: LText(
                          item.kind == EntityKind.result
                              ? 'Results review'
                              : 'Resources review',
                          style: const TextStyle(fontSize: 11, color: muted)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () =>
                          context.push('/record/${item.kind.name}/${item.id}')),
              ]))),
      const SizedBox(height: 18),
      DashboardColumns(
          left: DashboardPanel(
              title: 'Recent administrator activity',
              subtitle: 'Changes saved in this workspace',
              action: 'View all',
              onAction: () => navigate('audit'),
              child: Column(children: [
                if (log.isEmpty)
                  const EmptyPanel('A clear starting point',
                      'Saved changes will appear here with an actor and timestamp.',
                      icon: Icons.history),
                for (final entry in log.take(4))
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                          backgroundColor: Color(0xffedf3ff),
                          child: Text('NM',
                              style: TextStyle(fontSize: 12, color: blue))),
                      title: LText('${entry['action']}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${entry['target']} • ${entry['time'].toString().replaceFirst('T', ' ').split('.').first}',
                          style: const TextStyle(fontSize: 11, color: muted)),
                      onTap: () => navigate('audit')),
              ])),
          right: DashboardPanel(
              title: 'School agenda',
              subtitle: 'Published events and performing arts',
              action: 'Calendar',
              onAction: () => navigate('calendar'),
              child: Column(children: [
                if (r
                    .records(EntityKind.event)
                    .where((x) => x['status'] == 'Published')
                    .isEmpty)
                  const EmptyPanel('No scheduled events',
                      'Published school events will appear here.'),
                for (final event in r
                    .records(EntityKind.event)
                    .where((x) => x['status'] == 'Published')
                    .take(3))
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0xfff1ecff),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.event_outlined,
                              color: Color(0xff8055d9), size: 20)),
                      title: Text(event['name'],
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${event['date']} • ${event['time']}\n${event['venue']}',
                          style: const TextStyle(fontSize: 11, color: muted)),
                      onTap: () => context.push('/record/event/${event.id}')),
              ]))),
    ]));
  }
}
