import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fa(Object v) {
  const f = '۰۱۲۳۴۵۶۷۸۹';
  return v.toString().replaceAllMapped(RegExp(r'\d'), (m) => f[int.parse(m[0]!)]);
}

String nf(int n) =>
    fa(n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '٬'));

const typeLabel = {
  'personal': 'شخصی', 'journalist': 'شخصی / خبرنگار', 'channel': 'کانال عمومی', 'vip': 'اشتراک طلایی VIP', 'org': 'سازمانی',
};
// کلید → (برچسب، نوع pill)
const badgeInfo = {
  'blue': ('تیک آبی فعال', 'g'), 'gold': ('نشان طلایی', 'y'), 'org': ('تیک آبی سازمانی', 'b'),
  'pending': ('در انتظار بررسی', 'r'), 'none': ('بدون نشان', 'n'),
};
const sevInfo = {'crit': ('بحرانی', 'r'), 'high': ('بالا', 'r'), 'mid': ('متوسط', 'y'), 'low': ('عادی', 'n')};
const statusInfo = {
  'desk': ('میز کار بازرس', 'b'), 'wait': ('در صف انتظار', 'n'), 'legal': ('ارجاع حقوقی', 'y'),
  'banned': ('مسدودشده دائم', 'g'), 'rej': ('ردشکایت', 'n'), 'warn': ('اخطار داده شد', 'y'), 'restr': ('محدودیت چت ۷ روز', 'y'),
};
const cats = [
  ('all', 'همه گزارش‌ها', 84), ('phish', 'کلاهبرداری و فیشینگ', 28), ('imp', 'جعل هویت و سایبری', 19),
  ('harass', 'آزار و اذیت', 22), ('spam', 'هرزنامه و اسپم', 15),
];
const hasBadge = ['blue', 'org', 'gold'];

class AUser {
  String n, u, t, b, d, s; // نام، شناسه، نوع، نشان، تاریخ عضویت، وضعیت (active/suspended)
  AUser(this.n, this.u, this.t, this.b, this.d, this.s);
}

class QItem {
  final String n, u, d, doc;
  QItem(this.n, this.u, this.d, this.doc);
}

class Case {
  final int id, sc;
  final String u, n, cat, cl, src, sev, tm;
  String st;
  Case(this.id, this.u, this.n, this.cat, this.cl, this.src, this.sev, this.sc, this.tm, this.st);
}

class BanInfo {
  final int id;
  final String u, time, basis, note;
  final bool sess, hw, purge, legal;
  BanInfo(this.id, this.u, this.time, this.basis, this.note, this.sess, this.hw, this.purge, this.legal);
}

class AdminState extends ChangeNotifier {
  int page = 1; // 0 داشبورد، 1 تأیید هویت، 2 تخلفات، 3 کانال‌ها، 4 تنظیمات
  bool dark = false, doneView = false;
  int vd = 0, pd = 0, urgent = 84, banned = 142, sel = 9082;
  BanInfo? last;
  SharedPreferences? _p;

  final users = <AUser>[
    AUser('سارا رضایی', 'sara_ux', 'personal', 'blue', '۱۴۰۲/۰۷/۱۴', 'active'),
    AUser('کیان پارسا', 'kian_parsa', 'vip', 'gold', '۱۴۰۱/۱۱/۲۰', 'active'),
    AUser('پویان احمدی', 'pouyan_ah', 'personal', 'none', '۱۴۰۲/۰۲/۰۳', 'active'),
    AUser('کانال اخبار و تکنولوژی', 'ai_news', 'channel', 'org', '۱۴۰۰/۰۵/۱۱', 'active'),
    AUser('مهرداد جمشیدی', 'mehrdad_j', 'journalist', 'pending', '۱۴۰۲/۱۲/۰۱', 'active'),
    AUser('دکتر کاظمی', 'dr_kazemi', 'personal', 'pending', '۱۴۰۲/۰۶/۱۸', 'active'),
    AUser('بانک ملت (جعلی)', 'mellat_fake_ebank', 'org', 'none', '۱۴۰۳/۰۱/۱۲', 'suspended'),
    AUser('کانال تخفیف دیجی‌مارکت', 'digi_off_iran', 'channel', 'none', '۱۴۰۳/۰۱/۲۰', 'active'),
    AUser('سهراب احسانی', 'sohrab_photo_art', 'personal', 'blue', '۱۴۰۱/۰۳/۰۹', 'active'),
    AUser('شرکت فناوران نوین', 'fanavaran_co', 'org', 'org', '۱۴۰۰/۱۰/۰۲', 'active'),
  ];

  final queue = <QItem>[
    QItem('سارا رضایی', 'sara_ux', 'طراح ارشد رابط کاربری', 'کارت ملی و مدارک شغلی بارگذاری شد'),
    QItem('کانال هوش مصنوعی', 'tech_ai', 'کانال عمومی با ۱۲.۸ هزار دنبال‌کننده', 'استعلام دامنه رسمی تأیید شد'),
    QItem('دکتر کاظمی', 'dr_kazemi', 'فوق تخصص قلب و عروق', 'شماره نظام پزشکی استعلام شد'),
  ];

  final cases = <Case>[
    Case(9082, 'crypto_fast_profit', 'ارز دیجیتال سود تضمینی', 'phish', 'کلاهبرداری و فیشینگ رمزارز', '۱۲ شاکی + هوش مصنوعی', 'crit', 98, 'امروز ۱۲:۲۲', 'desk'),
    Case(9081, 'payam_support_admin', 'پشتیبانی و تأیید هویت', 'imp', 'جعل هویت تیم پشتیبانی پیام', 'هوش مصنوعی', 'crit', 91, 'امروز ۱۲:۲۰', 'wait'),
    Case(9079, 'digi_off_iran', 'کانال تخفیف دیجی‌مارکت', 'spam', 'تبلیغات فریبنده و هرزنگاری', '۶ شاکی', 'mid', 48, 'امروز ۱۱:۱۵', 'wait'),
    Case(9076, 'wolf_alpha_7', 'گرگ شب (ناشناس)', 'harass', 'تهدید و تهدید خشونت', '۹ شاکی', 'high', 87, 'دیروز ۲۳:۴۰', 'legal'),
    Case(9071, 'mellat_fake_ebank', 'بانکداری آنلاین ملت‌کارت', 'phish', 'درگاه بانکی جعلی و نقض نام تجاری', 'هوش مصنوعی', 'crit', 100, 'دیروز ۱۸:۲۰', 'banned'),
    Case(9065, 'sohrab_photo_art', 'سهراب احسانی (عکاسی)', 'spam', 'ادعای نقض کپی‌رایت تصویر', '۱ شاکی', 'low', 22, 'دیروز ۱۰:۳۰', 'rej'),
  ];

  int get verified => 1240 + vd;
  int get pending => (38 + pd).clamp(0, 1 << 30);
  Case get current => cases.firstWhere((c) => c.id == sel, orElse: () => cases.first);

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    dark = _p!.getBool('dark') ?? false;
  }

  void go(int i) { page = i; notifyListeners(); }
  void toggleDark() { dark = !dark; _p?.setBool('dark', dark); notifyListeners(); }

  void setBadge(String u, String b) {
    final x = users.where((e) => e.u == u).firstOrNull;
    if (x == null) return;
    final had = hasBadge.contains(x.b), was = x.b == 'pending';
    x.b = b;
    final has = hasBadge.contains(b);
    if (has && !had) vd++;
    if (!has && had) vd--;
    if (was && b != 'pending') pd--;
    notifyListeners();
  }

  void toggleSuspend(String u) {
    final x = users.firstWhere((e) => e.u == u);
    x.s = x.s == 'active' ? 'suspended' : 'active';
    notifyListeners();
  }

  void grant(String u, String b) {
    var x = users.where((e) => e.u == u).firstOrNull;
    if (x == null) {
      x = AUser(u, u, b == 'gold' ? 'vip' : b == 'org' ? 'org' : 'personal', 'none', fa('۱۴۰۳/۰۱/۰۱'), 'active');
      users.insert(0, x);
    }
    setBadge(u, b);
  }

  void qDecide(int i, bool ok) {
    final q = queue.removeAt(i);
    pd--;
    if (ok) {
      vd++;
      final x = users.where((e) => e.u == q.u).firstOrNull;
      if (x != null) x.b = 'blue';
    }
    notifyListeners();
  }

  void selectCase(int id) { sel = id; doneView = false; page = 2; notifyListeners(); }

  void _next() {
    final n = cases.where((x) => x.id != sel && ['wait', 'legal', 'desk'].contains(x.st)).firstOrNull;
    if (n != null) sel = n.id;
  }

  void act(String k) {
    current.st = k;
    urgent = (urgent - 1).clamp(0, 1 << 30);
    _next();
    notifyListeners();
  }

  void ban(BanInfo b) {
    current.st = 'banned';
    urgent = (urgent - 1).clamp(0, 1 << 30);
    banned++;
    last = b;
    doneView = true;
    notifyListeners();
  }

  void backToBench() {
    doneView = false;
    _next();
    notifyListeners();
  }
}

final AdminState admin = AdminState();
