// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../features/workspace.dart';
import '../features/record_screens.dart';
import 'localization/app_language.dart';
import '../shared/components/premium_surface.dart';

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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2869f0))
              .copyWith(
                  primary: const Color(0xff2869f0),
                  surface: Colors.white,
                  onSurface: const Color(0xff17233a)),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0),
          dividerTheme:
              const DividerThemeData(color: Color(0xffe5ebf3), thickness: 1),
          cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xd8ffffff),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xffdce5ef)))),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 46),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  side: const BorderSide(color: Color(0xffdce5ef)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)))),
          chipTheme: ChipThemeData(
              side: const BorderSide(color: Color(0xffdce5ef)),
              backgroundColor: Colors.transparent,
              selectedColor: const Color(0xffe8f0ff),
              labelStyle: const TextStyle(fontSize: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9))),
          navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: Color(0xffe8f0ff),
              labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10))),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xc9ffffff),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: Color(0xffd9e2ed))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: Color(0xffd9e2ed)))),
        ),
        builder: (context, child) => BackdropGroup(
                child: Stack(fit: StackFit.expand, children: [
              const Positioned.fill(child: LiquidGlassBackdrop(dark: false)),
              MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                          (r.state['textScale'] as num?)?.toDouble() ?? 1)),
                  child: child!)
            ])));
  }
}
