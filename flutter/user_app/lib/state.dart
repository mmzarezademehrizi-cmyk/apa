import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fa(Object v) {
  const f = '۰۱۲۳۴۵۶۷۸۹';
  return v.toString().replaceAllMapped(RegExp(r'\d'), (m) => f[int.parse(m[0]!)]);
}

String nowFa() {
  final n = DateTime.now();
  return fa('${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}');
}

enum ChatType { personal, group, channel }

class Person {
  final String id, name, user, phone, bio;
  final bool verified, online;
  const Person(this.id, this.name, this.user, this.phone, this.bio,
      {this.verified = false, this.online = false});
}

const people = <String, Person>{
  'sara': Person('sara', 'سارا رضایی', 'sara_ux', '+۹۸ ۹۱۲ ۳۴۵ ۶۷۸۹',
      'طراح رابط کاربری در حال خلق تجارب معنادار ✨',
      verified: true, online: true),
  'pouyan': Person('pouyan', 'پویان احمدی', 'pouyan_ah', '+۹۸ ۹۱۹ ۱۱۱ ۲۲۳۳', 'توسعه‌دهنده موبایل'),
  'kazemi': Person('kazemi', 'دکتر کاظمی', 'dr_kazemi', '+۹۸ ۹۱۲ ۷۷۷ ۸۸۹۹', 'متخصص قلب و عروق',
      verified: true),
  'mehrdad': Person('mehrdad', 'مهرداد جمشیدی', 'mehrad_j', '+۹۸ ۹۳۰ ۵۵۵ ۱۲۱۲', 'خبرنگار و عکاس',
      online: true),
  'parinaz': Person('parinaz', 'پریناز', 'parinaz', '+۹۸ ۹۱۰ ۲۲۲ ۳۳۴۴', ''),
  'ali': Person('ali', 'علی', 'ali_k', '+۹۸ ۹۱۲ ۹۹۹ ۰۰۱۱', ''),
};

class Msg {
  final bool mine;
  final String time;
  final String text;
  final String? who, file, replyName, replyText;
  final int? voiceSec;
  String? react;
  int rc;
  bool seen;
  Msg({
    required this.mine,
    required this.time,
    this.text = '',
    this.who,
    this.file,
    this.voiceSec,
    this.replyName,
    this.replyText,
    this.react,
    this.rc = 0,
    this.seen = false,
  });
}

class Chat {
  final String id, name;
  final ChatType type;
  final bool verified;
  final String? views;
  String time, last;
  int unread;
  bool pinned;
  String? status; // 'sent' | 'seen'
  final List<Msg> msgs;
  Chat(this.id, this.name, this.type, this.time, this.last,
      {this.unread = 0,
      this.pinned = false,
      this.status,
      this.verified = false,
      this.views,
      List<Msg>? msgs})
      : msgs = msgs ?? [];
}

List<Chat> _seed() => [
      Chat('design', 'تیم طراحی محصول', ChatType.group, '۱۰:۴۵',
          'فرهاد: فایل فیگما نهایی ارسال شد، بازبینی کنین',
          unread: 5,
          pinned: true,
          msgs: [
            Msg(mine: false, who: 'مریم', time: '۱۰:۰۵', text: 'سلام تیم! جلسه امروز ساعت ۱۰ بود؟'),
            Msg(mine: false, who: 'فرهاد', time: '۱۰:۴۵', text: 'فایل فیگما نهایی ارسال شد، بازبینی کنین'),
          ]),
      Chat('sara', 'سارا رضایی', ChatType.personal, '۰۹:۱۵', 'فایل‌ها رو برات فرستادم، چک کردی؟',
          pinned: true,
          status: 'seen',
          msgs: [
            Msg(mine: false, time: '۱۰:۲۸', text: 'سلام کیان جان، وضعیت طرح‌های جدید اپلیکیشن به کجا رسید؟'),
            Msg(mine: true, time: '۱۰:۳۰', seen: true, text: 'سلام سارا! طرح‌های پروتوتایپ آماده شده، الان برات خروجی می‌فرستم.'),
            Msg(mine: false, time: '۱۰:۳۲', voiceSec: 38),
            Msg(mine: true, time: '۱۰:۳۴', seen: true, file: 'Figma_Final_v2.png', text: 'نسخه دسکتاپ و موبایل پیوست شد', react: '❤️', rc: 2),
            Msg(mine: false, time: '۱۰:۳۶', text: 'فوق‌العاده شده! مخصوصاً رنگ‌بندی نیلی و چیدمان فارسی دست درد نکنه 🔥', replyName: 'کیان', replyText: 'نسخه دسکتاپ و موبایل پیوست شد', react: '👍', rc: 1),
          ]),
      Chat('pouyan', 'پویان احمدی', ChatType.personal, 'دیروز', 'جلسه فردا ساعت ۱۱ هماهنگه؟',
          unread: 2,
          msgs: [Msg(mine: false, time: 'دیروز', text: 'جلسه فردا ساعت ۱۱ هماهنگه؟')]),
      Chat('ai', 'کانال تکنولوژی و هوش مصنوعی', ChatType.channel, 'دیروز', '📢 🚀 نسخه جدید منتشر شد…',
          verified: true,
          views: '۱۴.۲K',
          msgs: [Msg(mine: false, time: 'دیروز', text: '🚀 نسخه جدید منتشر شد؛ پشتیبانی کامل از مدل‌های چندزبانه و فارسی.')]),
      Chat('family', 'خانواده ❤️', ChatType.group, '۳ روز پیش',
          'مادر: جمعه همه خونه ما دعوتین، خورشت قورمه‌سبزی داریم',
          status: 'sent',
          msgs: [Msg(mine: false, who: 'مادر', time: '۳ روز پیش', text: 'جمعه همه خونه ما دعوتین، خورشت قورمه‌سبزی داریم')]),
      Chat('kazemi', 'دکتر کاظمی', ChatType.personal, '۴ روز پیش', '🎙 پیام صوتی (۰:۴۲)',
          status: 'seen', msgs: [Msg(mine: false, time: '۴ روز پیش', voiceSec: 42)]),
    ];

const _replies = [
  'باشه، ممنون! 🙏',
  'عالیه 👌',
  'بذار یه نگاه بندازم و خبرت می‌کنم',
  'حتماً، فردا در موردش صحبت می‌کنیم',
  '😂👍',
  'دمت گرم، دقیقاً همین رو می‌خواستم',
];

class AppState extends ChangeNotifier {
  final List<Chat> chats = _seed();
  final Set<String> muted = {}, blocked = {};
  bool dark = false, notif = true, clean = true;
  String? typingId, openId;
  SharedPreferences? _p;
  final _rnd = Random();

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    dark = _p!.getBool('dark') ?? false;
    notif = _p!.getBool('notif') ?? true;
    clean = _p!.getBool('clean') ?? true;
    muted.addAll(_p!.getStringList('muted') ?? []);
    blocked.addAll(_p!.getStringList('blocked') ?? []);
  }

  void _persist() {
    _p?.setBool('dark', dark);
    _p?.setBool('notif', notif);
    _p?.setBool('clean', clean);
    _p?.setStringList('muted', muted.toList());
    _p?.setStringList('blocked', blocked.toList());
  }

  int get unreadTotal => chats.fold(0, (a, c) => a + c.unread);

  Chat? chat(String id) {
    for (final c in chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  Chat ensureChat(String personId) {
    final ex = chat(personId);
    if (ex != null) return ex;
    final c = Chat(personId, people[personId]!.name, ChatType.personal, nowFa(), '');
    chats.add(c);
    notifyListeners();
    return c;
  }

  void toggleDark() { dark = !dark; _persist(); notifyListeners(); }
  void toggleNotif() { notif = !notif; _persist(); notifyListeners(); }
  void toggleClean() { clean = !clean; _persist(); notifyListeners(); }
  void toggleMute(String id) { muted.contains(id) ? muted.remove(id) : muted.add(id); _persist(); notifyListeners(); }
  void toggleBlock(String id) { blocked.contains(id) ? blocked.remove(id) : blocked.add(id); _persist(); notifyListeners(); }

  void markRead(String id) {
    final c = chat(id);
    if (c != null && c.unread > 0) { c.unread = 0; notifyListeners(); }
  }

  void toggleReact(Msg m) {
    if (m.react != null) { m.react = null; m.rc = 0; } else { m.react = '❤️'; m.rc = 1; }
    notifyListeners();
  }

  void send(String id, String text) {
    final c = chat(id);
    final t = text.trim();
    if (c == null || t.isEmpty) return;
    final m = Msg(mine: true, time: nowFa(), text: t);
    c.msgs.add(m);
    c.last = t; c.time = m.time; c.status = 'sent';
    notifyListeners();
    Timer(const Duration(milliseconds: 900), () { m.seen = true; c.status = 'seen'; notifyListeners(); });
    if (c.type == ChatType.personal) {
      Timer(const Duration(milliseconds: 1100), () { typingId = id; notifyListeners(); });
      Timer(const Duration(milliseconds: 2600), () {
        typingId = null;
        final r = _replies[_rnd.nextInt(_replies.length)];
        c.msgs.add(Msg(mine: false, time: nowFa(), text: r));
        c.last = r; c.time = nowFa();
        if (openId != id) c.unread++;
        notifyListeners();
      });
    }
  }
}

/// نمونهٔ سراسری برای سادگی؛ در صورت نیاز می‌توان با Provider/Riverpod جایگزین کرد.
final AppState app = AppState();
