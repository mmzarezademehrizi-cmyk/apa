import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state.dart' show fa;
import 'widgets.dart';

/// ثبت‌نام/ورود محلی (روی همین دستگاه). برای بک‌اند واقعی فقط
/// متدهای register/login/logout را به API وصل کنید.
class AuthService extends ChangeNotifier {
  AuthService(this.prefix);
  final String prefix;
  SharedPreferences? _p;
  List<Map<String, dynamic>> _users = [];
  String? _uid;
  int _fails = 0, _lockUntil = 0;

  String get _kUsers => '$prefix.users';

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p!.getString(_kUsers);
    _users = raw == null
        ? []
        : (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    _uid = _p!.getString('$prefix.session');
    _lockUntil = _p!.getInt('$prefix.lock') ?? 0;
  }

  bool get hasUsers => _users.isNotEmpty;
  Map<String, dynamic>? get current {
    for (final u in _users) {
      if (u['id'] == _uid) return u;
    }
    return null;
  }

  bool get loggedIn => current != null;

  String get masked {
    final u = current;
    if (u == null) return '';
    final v = u['v'] as String;
    return u['t'] == 'email'
        ? '${v[0]}***${v.substring(v.indexOf('@') - 1)}'
        : '${v.substring(0, 4)}***${v.substring(v.length - 4)}';
  }

  static String _en(String s) {
    const pf = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      var i = pf.indexOf(c);
      if (i < 0) i = ar.indexOf(c);
      b.write(i >= 0 ? '$i' : c);
    }
    return b.toString();
  }

  /// ایمیل یا موبایل ایران را نرمال می‌کند؛ نامعتبر → null
  static ({String type, String value})? normalizeId(String raw) {
    var v = _en(raw.trim());
    if (v.isEmpty) return null;
    if (v.contains('@')) {
      v = v.toLowerCase();
      return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(v) ? (type: 'email', value: v) : null;
    }
    var p = v.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (p.startsWith('0098')) {
      p = '0${p.substring(4)}';
    } else if (p.startsWith('98')) {
      p = '0${p.substring(2)}';
    }
    return RegExp(r'^09\d{9}$').hasMatch(p) ? (type: 'phone', value: p) : null;
  }

  Future<String> _hash(String pw, List<int> salt) async {
    final alg = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 100000, bits: 256);
    final key = await alg.deriveKeyFromPassword(password: pw, nonce: salt);
    return base64Encode(await key.extractBytes());
  }

  Future<void> _saveUsers() => _p!.setString(_kUsers, jsonEncode(_users));

  Future<String?> register(String idRaw, String pw, String pw2, {bool adminOnly = false}) async {
    final id = normalizeId(idRaw);
    if (id == null) return 'ایمیل یا شماره موبایل معتبر وارد کنید (مثال: 09121234567)';
    if (pw.length < 8 || !RegExp(r'\d').hasMatch(pw) || !RegExp(r'\p{L}', unicode: true).hasMatch(pw)) {
      return 'رمز عبور باید حداقل ۸ کاراکتر و شامل حرف و عدد باشد';
    }
    if (pw != pw2) return 'تکرار رمز عبور با رمز عبور یکسان نیست';
    if (adminOnly && _users.isNotEmpty) return 'حساب مدیر قبلاً ایجاد شده است';
    if (_users.any((u) => u['v'] == id.value)) return 'این حساب قبلاً ثبت‌نام کرده است';
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final uid = '${DateTime.now().microsecondsSinceEpoch}${rnd.nextInt(1 << 32)}';
    _users.add({'id': uid, 't': id.type, 'v': id.value, 's': base64Encode(salt), 'h': await _hash(pw, salt)});
    await _saveUsers();
    _uid = uid;
    await _p!.setString('$prefix.session', uid);
    notifyListeners();
    return null;
  }

  Future<String?> login(String idRaw, String pw) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lockUntil > now) {
      return 'تلاش ناموفق زیاد بود؛ ${fa(((_lockUntil - now) / 1000).ceil())} ثانیه صبر کنید';
    }
    final id = normalizeId(idRaw);
    Map<String, dynamic>? u;
    if (id != null) {
      for (final x in _users) {
        if (x['v'] == id.value) u = x;
      }
    }
    final ok = u != null && await _hash(pw, base64Decode(u['s'] as String)) == u['h'];
    if (!ok) {
      if (++_fails >= 5) {
        _fails = 0;
        _lockUntil = now + 30000;
        await _p!.setInt('$prefix.lock', _lockUntil);
      }
      return 'ایمیل/شماره یا رمز عبور اشتباه است';
    }
    _fails = 0;
    _uid = u!['id'] as String;
    await _p!.setString('$prefix.session', _uid!);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _uid = null;
    await _p?.remove('$prefix.session');
    notifyListeners();
  }
}

/// در main() مقداردهی می‌شود.
late final AuthService auth;

class AuthGate extends StatelessWidget {
  final Widget child;
  final bool adminMode;
  const AuthGate({super.key, required this.child, this.adminMode = false});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: auth,
        builder: (context, _) => auth.loggedIn ? child : AuthScreen(adminMode: adminMode),
      );
}

Future<void> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('خروج از حساب'),
      content: const Text('از حساب خود خارج می‌شوید؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج', style: TextStyle(color: kRed))),
      ],
    ),
  );
  if (ok == true) await auth.logout();
}

class AuthScreen extends StatefulWidget {
  final bool adminMode;
  const AuthScreen({super.key, this.adminMode = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _id = TextEditingController(), _pw = TextEditingController(), _pw2 = TextEditingController();
  bool _registerTab = false, _hide = true, _busy = false;
  String _err = '';

  bool get _reg => widget.adminMode ? !auth.hasUsers : _registerTab;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() { _busy = true; _err = ''; });
    final e = _reg
        ? await auth.register(_id.text, _pw.text, _pw2.text, adminOnly: widget.adminMode)
        : await auth.login(_id.text, _pw.text);
    if (!mounted) return;
    setState(() { _busy = false; _err = e ?? ''; if (e != null) { _pw.clear(); _pw2.clear(); } });
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final reg = _reg;
    InputDecoration dec(String hint, {Widget? suffix}) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.mut, fontSize: 13),
          filled: true,
          fillColor: p.field,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPri, width: 1.6)),
        );
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
    final eye = TextButton(
        onPressed: () => setState(() => _hide = !_hide),
        child: Text(_hide ? 'نمایش' : 'پنهان', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)));
    Widget tab(String t, bool on, VoidCallback f) => Expanded(
          child: GestureDetector(
            onTap: f,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: on ? p.card : Colors.transparent, borderRadius: BorderRadius.circular(99)),
              child: Text(t, style: TextStyle(fontWeight: FontWeight.w600, color: on ? kPri : p.mut)),
            ),
          ),
        );
    final sub = widget.adminMode
        ? (reg ? 'ایجاد حساب مدیر (اولین ورود)' : 'ورود به پنل مدیریت')
        : (reg ? 'ایجاد حساب جدید' : 'ورود به حساب');
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: PCard(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                child: AutofillGroup(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Center(
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), kPri2], begin: Alignment.topRight, end: Alignment.bottomLeft),
                        ),
                        child: Icon(widget.adminMode ? Icons.verified_user_outlined : Icons.chat_bubble_outline, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.adminMode ? 'پنل مدیریت پیام' : 'پیام',
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    Text(sub, textAlign: TextAlign.center, style: TextStyle(color: p.mut, fontSize: 14)),
                    if (!widget.adminMode) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(99)),
                        child: Row(children: [
                          tab('ورود', !reg, () => setState(() { _registerTab = false; _err = ''; })),
                          tab('ثبت‌نام', reg, () => setState(() { _registerTab = true; _err = ''; })),
                        ]),
                      ),
                    ],
                    label('ایمیل یا شماره موبایل'),
                    TextField(
                      controller: _id,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: dec('name@example.com  یا  09123456789'),
                    ),
                    label('رمز عبور'),
                    TextField(
                      controller: _pw,
                      obscureText: _hide,
                      textDirection: TextDirection.ltr,
                      autofillHints: [reg ? AutofillHints.newPassword : AutofillHints.password],
                      textInputAction: reg ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: reg ? null : (_) => _submit(),
                      decoration: dec('', suffix: eye),
                    ),
                    if (reg) ...[
                      label('تکرار رمز عبور'),
                      TextField(
                        controller: _pw2,
                        obscureText: _hide,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        inputFormatters: [LengthLimitingTextInputFormatter(128)],
                        decoration: dec('', suffix: eye),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('حداقل ۸ کاراکتر، شامل حرف و عدد', style: TextStyle(color: p.mut, fontSize: 12)),
                      ),
                    ],
                    SizedBox(
                      height: 40,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(_err, style: const TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text(_busy ? 'لطفاً صبر کنید…' : reg ? 'ثبت‌نام' : 'ورود',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    Text('فعلاً حساب‌ها فقط روی همین دستگاه ذخیره می‌شوند.',
                        textAlign: TextAlign.center, style: TextStyle(color: p.mut, fontSize: 11.5)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
