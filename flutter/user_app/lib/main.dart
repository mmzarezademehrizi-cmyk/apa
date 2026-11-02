import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home.dart';
import 'state.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const EchoPayamApp());
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Pal.dark : Pal.light;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: p.bg,
    dividerColor: p.line,
    colorScheme: ColorScheme.fromSeed(seedColor: kPri, brightness: b)
        .copyWith(primary: kPri, surface: p.card),
    appBarTheme: AppBarTheme(
      backgroundColor: p.card,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      indicatorColor: p.chip,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500)),
    ),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? kPri : p.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

class EchoPayamApp extends StatelessWidget {
  const EchoPayamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final dark = app.dark;
        SystemChrome.setSystemUIOverlayStyle(
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
        return MaterialApp(
          title: 'پیام',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fa'),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          // RTL به‌صورت پیش‌فرض (بدون نیاز به flutter_localizations)
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const HomeShell(),
        );
      },
    );
  }
}
