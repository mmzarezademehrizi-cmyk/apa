import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth.dart';
import 'pages.dart';
import 'state.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  auth = AuthService('echo_payam_admin');
  await auth.load();
  await admin.load();
  runApp(const AdminApp());
}

ThemeData _theme(Brightness b) {
  final p = b == Brightness.dark ? Pal.dark : Pal.light;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: b == Brightness.dark ? p.bg : const Color(0xFFF1F5F9),
    dividerColor: p.line,
    colorScheme: ColorScheme.fromSeed(seedColor: kPri, brightness: b).copyWith(primary: kPri, surface: p.card),
    appBarTheme: AppBarTheme(
      backgroundColor: p.card, foregroundColor: p.ink, elevation: 0, scrolledUnderElevation: 0.5,
      titleTextStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: p.card),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0F172A),
      contentTextStyle: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kPri : p.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: admin,
      builder: (context, _) {
        SystemChrome.setSystemUIOverlayStyle(admin.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
        return MaterialApp(
          title: 'پنل مدیریت پیام',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fa'),
          themeMode: admin.dark ? ThemeMode.dark : ThemeMode.light,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const AuthGate(adminMode: true, child: AdminShell()),
        );
      },
    );
  }
}
