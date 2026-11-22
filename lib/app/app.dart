// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../features/workspace.dart';
import '../features/record_screens.dart';
import 'localization/app_language.dart';

class AdminApp extends ConsumerStatefulWidget {
  const AdminApp({super.key});
  @override
  ConsumerState<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends ConsumerState<AdminApp> {
  @override
  void initState() {
    super.initState();
    GoRouter.optionURLReflectsImperativeAPIs = true;
  }

  late final router = GoRouter(
      initialLocation: '/home',
      refreshListenable: ref.read(adminRepositoryProvider),
      redirect: (c, s) {
        final signedIn = ref.read(adminRepositoryProvider).signedIn;
        if (!signedIn && s.uri.path != '/login') return '/login';
        if (signedIn && s.uri.path == '/login') return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (c, s) => const AdminLogin()),
        GoRoute(
            path: '/new/:kind',
            builder: (c, s) => RecordEditor(kind: s.pathParameters['kind']!)),
        GoRoute(
            path: '/edit/:kind/:id',
            builder: (c, s) => RecordEditor(
                kind: s.pathParameters['kind']!, id: s.pathParameters['id']!)),
        GoRoute(
            path: '/record/:kind/:id',
            builder: (c, s) => RecordDetail(
                kind: s.pathParameters['kind']!, id: s.pathParameters['id']!)),
        GoRoute(
            path: '/register/:id',
            builder: (c, s) =>
                RegisterScreen(classId: s.pathParameters['id']!)),
        GoRoute(
            path: '/:page',
            builder: (c, s) => AdminWorkspace(page: s.pathParameters['page']!))
      ]);
  @override
  Widget build(BuildContext context) {
    final r = ref.watch(adminRepositoryProvider);
    return MaterialApp.router(
        title: 'Lucky Dube • Administration',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        locale: Locale(r.language, 'ZA'),
        supportedLocales: const [Locale('en', 'ZA'), Locale('zu', 'ZA')],
        localizationsDelegates: const [
          AppLanguage.delegate,
          // ignore: deprecated_member_use
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          // ignore: deprecated_member_use
          GlobalCupertinoLocalizations.delegate
        ],
        theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xff2563eb))
                    .copyWith(
                        primary: const Color(0xff2563eb),
                        surface: Colors.white,
                        onSurface: const Color(0xff22334b)),
            scaffoldBackgroundColor: const Color(0xfff7faff),
            appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white, scrolledUnderElevation: 0),
            cardTheme: CardThemeData(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xffe2e8f0)))),
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xfff0f5fb),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none))),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                    (r.state['textScale'] as num?)?.toDouble() ?? 1)),
            child: child!));
  }
}
