// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app/localization/app_language.dart';
import '../../data/admin_repository.dart';
import 'admin_components.dart';
import 'dashboard_components.dart';
import 'premium_surface.dart';

/// Adapts OG Vibes' grouped sidebar, account footer and breadcrumb topbar.
class AdminShell extends StatefulWidget {
  final String page;
  final Map<String, String> navigation;
  final IconData Function(String) icon;
  final ValueChanged<String> navigate;
  final LocalAdminRepository repository;
  final Widget child;
  const AdminShell(
      {super.key,
      required this.page,
      required this.navigation,
      required this.icon,
      required this.navigate,
      required this.repository,
      required this.child});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final shell = GlobalKey<ScaffoldState>();
  String get page => widget.page;
  Map<String, String> get navigation => widget.navigation;
  IconData Function(String) get icon => widget.icon;
  ValueChanged<String> get navigate => widget.navigate;
  LocalAdminRepository get repository => widget.repository;
  Widget get child => widget.child;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final roomy = MediaQuery.sizeOf(context).width >= 1200 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.2;
    final groups = {
      'WORKSPACE': ['home'],
      'PEOPLE': ['learners', 'staff', 'classes'],
      'TEACHING & LEARNING': [
        'subjects',
        'allocations',
        'timetable',
        'attendance',
        'results',
        'resources'
      ],
      'SCHOOL COMMUNITY': ['announcements', 'calendar', 'concerns'],
      'OPERATIONS': ['reports', 'audit', 'school', 'settings'],
    };
    Widget menu() => LiquidGlassSurface(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        blur: 20,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
              child: Row(children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: blue, borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: const Text('LD',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(repository.school['displayName']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ink)),
                      const SizedBox(height: 4),
                      const LText('ADMINISTRATION',
                          style: TextStyle(
                              color: blue,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2))
                    ])),
                if (!wide)
                  IconButton(
                      tooltip: tr(context, 'Close navigation'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20)),
              ])),
          const Divider(height: 1),
          Expanded(
              child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: [
                for (final group in groups.entries) ...[
                  Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 12, 8),
                      child: LText(group.key,
                          style: const TextStyle(
                              fontSize: 9,
                              color: muted,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700))),
                  for (final key in group.value)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: ListTile(
                            dense: true,
                            minVerticalPadding: 12,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            selected: page == key,
                            selectedTileColor: const Color(0xffeaf1ff),
                            selectedColor: blue,
                            iconColor: const Color(0xff718198),
                            textColor: const Color(0xff52627b),
                            leading: Icon(icon(key), size: 19),
                            title: LText(navigation[key]!,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: page == key
                                        ? FontWeight.w800
                                        : FontWeight.w600)),
                            trailing: page == key
                                ? const Icon(Icons.chevron_right, size: 16)
                                : null,
                            onTap: () {
                              if (!wide) Navigator.pop(context);
                              navigate(key);
                            })),
                ],
              ])),
          const Divider(height: 1),
          Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    dense: true,
                    leading: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xffe5efff),
                        child: Text('NM',
                            style: TextStyle(
                                color: blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800))),
                    title: const Text(LocalAdminRepository.administrator,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    subtitle: const LText('School administrator',
                        style: TextStyle(fontSize: 10, color: muted)),
                    onTap: () {
                      if (!wide) Navigator.pop(context);
                      navigate('settings');
                    }),
                TextButton.icon(
                    onPressed: repository.signOut,
                    style: TextButton.styleFrom(
                        foregroundColor: muted,
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(double.infinity, 44)),
                    icon: const Icon(Icons.logout, size: 17),
                    label: const LText('Sign out',
                        style: TextStyle(fontSize: 11))),
              ])),
        ]));
    Widget topbar() => LiquidGlassSurface(
        width: double.infinity,
        height: 72,
        padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 8),
        borderRadius: BorderRadius.zero,
        blur: 22,
        child: Row(children: [
          if (!wide)
            IconButton(
                tooltip: tr(context, 'Open navigation'),
                icon: const Icon(Icons.menu),
                onPressed: () => shell.currentState!.openDrawer()),
          if (roomy) ...[
            const LText('Admin control',
                style: TextStyle(color: muted, fontSize: 12)),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('/', style: TextStyle(color: Color(0xffc3ccda))))
          ],
          Expanded(
              child: LText(navigation[page] ?? 'Search workspace',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13))),
          if (roomy)
            OutlinedButton.icon(
                onPressed: () => navigate('search'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: muted,
                    minimumSize: const Size(220, 42),
                    backgroundColor: const Color(0xfff8fafd)),
                icon: const Icon(Icons.search, size: 18),
                label: const LText('Search workspace',
                    style: TextStyle(fontSize: 12)))
          else
            IconButton(
                tooltip: tr(context, 'Search workspace'),
                onPressed: () => navigate('search'),
                icon: const Icon(Icons.search)),
          const SizedBox(width: 8),
          const AdminLanguage(),
          if (roomy) ...[
            const SizedBox(width: 12),
            InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => navigate('settings'),
                child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xffedf3ff),
                    child: Text('NM',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: blue))))
          ],
        ]));
    return Scaffold(
        key: shell,
        drawer: wide
            ? null
            : Drawer(
                width: 280,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                child: SafeArea(child: menu())),
        body: SafeArea(
            child: Row(children: [
          if (wide)
            Container(
                width: 248,
                decoration: BoxDecoration(
                    color: const Color(0x12ffffff),
                    border: Border(
                        right: BorderSide(color: line.withValues(alpha: .6)))),
                child: menu()),
          Expanded(
              child: Column(children: [
            topbar(),
            Expanded(
                child: ListView(
                    padding: EdgeInsets.all(wide ? 28 : 16),
                    children: [
                  Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                child,
                                const SizedBox(height: 30),
                                const Divider(),
                                const SizedBox(height: 12),
                                const LText(
                                    'Optimal Growth Technologies SA • Information is saved on this device. No changes are sent to school services or the other apps.',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: muted,
                                        height: 1.7)),
                              ])))
                ]))
          ])),
        ])),
        bottomNavigationBar: wide
            ? null
            : LiquidGlassSurface(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.zero,
                blur: 22,
                child: NavigationBar(
                    selectedIndex: ['home', 'learners', 'timetable', 'concerns']
                            .contains(page)
                        ? ['home', 'learners', 'timetable', 'concerns']
                            .indexOf(page)
                        : 4,
                    onDestinationSelected: (i) {
                      if (i == 4) {
                        shell.currentState!.openDrawer();
                      } else {
                        navigate(
                            ['home', 'learners', 'timetable', 'concerns'][i]);
                      }
                    },
                    destinations: [
                      for (final key in [
                        'home',
                        'learners',
                        'timetable',
                        'concerns',
                        'more'
                      ])
                        NavigationDestination(
                            icon: Icon(key == 'more' ? Icons.menu : icon(key)),
                            label: tr(context,
                                key == 'more' ? 'More' : navigation[key]!))
                    ])));
  }
}
