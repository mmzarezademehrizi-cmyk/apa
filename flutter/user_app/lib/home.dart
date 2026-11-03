import 'package:flutter/material.dart';

import 'auth.dart';
import 'chat.dart';
import 'state.dart';
import 'widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final n = app.unreadTotal;
        Widget chatIcon(IconData d) => Badge(
            isLabelVisible: n > 0, label: Text(fa(n)), backgroundColor: kPri, child: Icon(d));
        return Scaffold(
          body: IndexedStack(index: i, children: [
            ChatsTab(onNew: () => setState(() => i = 2)),
            const CallsTab(),
            const ContactsTab(),
            const SettingsTab(),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: (v) => setState(() => i = v),
            destinations: [
              NavigationDestination(
                  icon: chatIcon(Icons.chat_bubble_outline), selectedIcon: chatIcon(Icons.chat_bubble), label: 'گفتگوها'),
              const NavigationDestination(
                  icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'تماس‌ها'),
              const NavigationDestination(
                  icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'مخاطبین'),
              const NavigationDestination(
                  icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'تنظیمات'),
            ],
          ),
        );
      },
    );
  }
}

AppBar _bar(BuildContext context, String title, {List<Widget>? actions}) => AppBar(
      leading: Padding(padding: const EdgeInsets.all(9), child: Avatar('کیان پارسا', size: 34)),
      title: Text(title, style: const TextStyle(color: kPri, fontWeight: FontWeight.w700, fontSize: 20)),
      actions: actions,
    );

// ───────────────────────── گفتگوها ─────────────────────────
class ChatsTab extends StatefulWidget {
  final VoidCallback onNew;
  const ChatsTab({super.key, required this.onNew});
  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  String filter = 'all', q = '';
  bool searching = false;

  static const _filters = [
    ['all', 'همه'], ['personal', 'شخصی'], ['group', 'گروه‌ها'], ['channel', 'کانال‌ها'], ['unread', 'خوانده‌نشده'],
  ];
  static const _stories = [['سارا', true], ['مهرداد', true], ['پریناز', true], ['علی', false]];

  bool _match(Chat c) {
    final okF = filter == 'all' ||
        (filter == 'unread' && c.unread > 0) ||
        c.type.name == filter;
    return okF && (q.isEmpty || '${c.name} ${c.last}'.contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.chats.where(_match).toList();
        final pinned = list.where((c) => c.pinned).toList();
        final recent = list.where((c) => !c.pinned).toList();
        final unreadChats = app.chats.where((c) => c.unread > 0).length;
        return Scaffold(
          appBar: _bar(context, 'پیام', actions: [
            IconButton(
                onPressed: () => setState(() { searching = !searching; if (!searching) q = ''; }),
                icon: const Icon(Icons.search)),
          ]),
          floatingActionButton: FloatingActionButton(
            onPressed: widget.onNew,
            backgroundColor: kPri,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.edit_outlined),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
            if (searching)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => q = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'جستجو در گفتگوها…',
                    filled: true,
                    fillColor: p.field,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                  ),
                ),
              ),
            const SectionTitle('وضعیت‌ها و داستان‌ها', color: null),
            SizedBox(
              height: 96,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _story(context, 'داستان شما', mine: true),
                for (final s in _stories) _story(context, s[0] as String, unseen: s[1] as bool),
              ]),
            ),
            SizedBox(
              height: 44,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      selected: filter == f[0],
                      onSelected: (_) => setState(() => filter = f[0]),
                      showCheckmark: false,
                      shape: const StadiumBorder(side: BorderSide.none),
                      backgroundColor: p.chip,
                      selectedColor: kPri,
                      labelStyle: TextStyle(
                          fontSize: 13, color: filter == f[0] ? Colors.white : p.chipText, fontWeight: FontWeight.w500),
                      label: Text(f[0] == 'all'
                          ? '${f[1]}  ${fa(app.chats.length)}'
                          : f[0] == 'unread' && unreadChats > 0 ? '${f[1]}  ${fa(unreadChats)}' : f[1]),
                    ),
                  ),
              ]),
            ),
            if (pinned.isNotEmpty) ...[
              const _Sec('گفتگوهای سنجاق‌شده', Icons.push_pin_outlined),
              PCard(child: DividerList([for (final c in pinned) ChatTile(c)])),
            ],
            if (recent.isNotEmpty) ...[
              const _Sec('گفتگوهای اخیر', null),
              PCard(child: DividerList([for (final c in recent) ChatTile(c)])),
            ],
            if (list.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(child: Text('گفتگویی پیدا نشد', style: TextStyle(color: p.mut)))),
          ]),
        );
      },
    );
  }

  Widget _story(BuildContext context, String name, {bool mine = false, bool unseen = false}) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 14),
      child: GestureDetector(
        onTap: () => toast(context, mine ? 'افزودن داستان به‌زودی' : 'داستان $name'),
        child: SizedBox(
          width: 66,
          child: Column(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unseen ? const SweepGradient(colors: [kPri, Color(0xFF38BDF8), kPri]) : null,
                  color: unseen ? null : p.line,
                ),
                child: Avatar(name, size: 56, online: unseen),
              ),
              if (mine)
                PositionedDirectional(
                  bottom: -2,
                  end: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        color: kPri, shape: BoxShape.circle, border: Border.all(color: p.bg, width: 2)),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _Sec extends StatelessWidget {
  final String t;
  final IconData? i;
  const _Sec(this.t, this.i);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Row(children: [
          if (i != null) ...[Icon(i, size: 15, color: Pal.of(context).mut), const SizedBox(width: 4)],
          Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pal.of(context).mut)),
        ]),
      );
}

class ChatTile extends StatelessWidget {
  final Chat c;
  const ChatTile(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final person = people[c.id];
    final isGroup = c.type == ChatType.group && c.last.contains(': ');
    final sender = isGroup ? c.last.split(': ').first : null;
    final text = isGroup ? c.last.split(': ').skip(1).join(': ') : c.last;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(c.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SizedBox(
          height: 52,
          child: Row(children: [
            Avatar(c.name, size: 52, online: person?.online == true || c.id == 'design'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (c.type == ChatType.group) Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Icon(Icons.group_outlined, size: 16, color: p.mut)),
                  Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                  if (c.verified) const Padding(padding: EdgeInsetsDirectional.only(start: 4), child: VerifiedBadge()),
                  const Spacer(),
                  Text(c.time, style: TextStyle(fontSize: 12, color: p.mut)),
                ]),
                Row(children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        if (sender != null)
                          TextSpan(text: '$sender: ', style: const TextStyle(color: kPri, fontWeight: FontWeight.w600)),
                        TextSpan(text: text),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, color: p.mut),
                    ),
                  ),
                  if (app.muted.contains(c.id)) Icon(Icons.notifications_off_outlined, size: 14, color: p.mut),
                  if (c.pinned) Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: Icon(Icons.push_pin_outlined, size: 14, color: p.mut)),
                  const SizedBox(width: 6),
                  if (c.unread > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: kPri, borderRadius: BorderRadius.circular(11)),
                      child: Text(fa(c.unread),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    )
                  else if (c.views != null)
                    Text(c.views!, style: TextStyle(fontSize: 12, color: p.mut))
                  else if (c.status != null)
                    Icon(c.status == 'seen' ? Icons.done_all : Icons.done,
                        size: 17, color: c.status == 'seen' ? kPri : p.mut),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── تماس‌ها ─────────────────────────
class CallsTab extends StatelessWidget {
  const CallsTab({super.key});
  static const _calls = [
    ['sara', 'in', 'امروز ۰۹:۱۰', false], ['pouyan', 'out', 'دیروز ۲۰:۳۰', true],
    ['mehrdad', 'miss', 'دیروز ۱۱:۰۵', false], ['kazemi', 'in', '۴ روز پیش', false],
  ];
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      appBar: _bar(context, 'تماس‌ها'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        PCard(
          child: DividerList([
            for (final c in _calls)
              InkWell(
                onTap: () => startCall(context, people[c[0]]!.name, c[3] as bool),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Avatar(people[c[0]]!.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(people[c[0]]!.name,
                            style: TextStyle(fontWeight: FontWeight.w600, color: c[1] == 'miss' ? kRed : p.ink)),
                        Text('${{'in': 'ورودی', 'out': 'خروجی', 'miss': 'بی‌پاسخ'}[c[1]]} · ${c[2]}',
                            style: TextStyle(fontSize: 12.5, color: p.mut)),
                      ]),
                    ),
                    Icon((c[3] as bool) ? Icons.videocam_outlined : Icons.call_outlined, color: kPri),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────── مخاطبین ─────────────────────────
class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      appBar: _bar(context, 'مخاطبین'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        PCard(
          child: DividerList([
            for (final x in people.values)
              InkWell(
                onTap: () {
                  app.ensureChat(x.id);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(x.id)));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Avatar(x.name, online: x.online),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(x.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (x.verified) const Padding(padding: EdgeInsetsDirectional.only(start: 4), child: VerifiedBadge()),
                        ]),
                        Text(x.online ? 'آنلاین' : 'به‌تازگی آنلاین بوده',
                            style: TextStyle(fontSize: 12.5, color: p.mut)),
                      ]),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────── تنظیمات ─────────────────────────
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        appBar: _bar(context, 'تنظیمات'),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          PCard(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                const Avatar('کیان پارسا', size: 64, online: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Text('کیان پارسا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      VerifiedBadge(size: 18),
                    ]),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(auth.masked, style: TextStyle(fontSize: 13, color: p.mut)),
                    ),
                  ]),
                ),
                IconButton.filledTonal(
                    onPressed: () => toast(context, 'ویرایش پروفایل'), icon: const Icon(Icons.edit_outlined, size: 18)),
                IconButton.filledTonal(
                    onPressed: () => toast(context, 'کد QR'), icon: const Icon(Icons.qr_code_2, size: 20)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const CircleAvatar(radius: 19, backgroundColor: kPri, child: Icon(Icons.workspace_premium, color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('نسخه طلایی فعال است', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('فضای ابری نامحدود و سرعت حداکثری', style: TextStyle(fontSize: 12, color: p.mut)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          const SectionTitle('عمومی و ظاهری'),
          PCard(
            child: DividerList([
              InfoRow(Icons.person_outline, 'حساب کاربری و پروفایل', sub: 'شماره تماس، نام کاربری، بیوگرافی',
                  onTap: () => toast(context, 'حساب کاربری')),
              InfoRow(Icons.palette_outlined, 'گفتگوها و تم',
                  sub: 'اندازه فونت، تصویر پس‌زمینه، انیمیشن‌ها',
                  tag: Tag(app.dark ? 'تم تیره' : 'تم نیلی'),
                  trailing: Switch(value: app.dark, onChanged: (_) => app.toggleDark()),
                  onTap: app.toggleDark),
              InfoRow(Icons.notifications_none, 'اعلان‌ها و صداها', sub: 'پیش‌نمایش پیام، گروه‌ها، زنگ تماس',
                  trailing: Switch(value: app.notif, onChanged: (_) => app.toggleNotif()), onTap: app.toggleNotif),
            ]),
          ),
          const SectionTitle('امنیت و ذخیره‌سازی'),
          PCard(
            child: DividerList([
              InfoRow(Icons.lock_outline, 'حریم خصوصی و امنیت', sub: 'تأیید دو مرحله‌ای، قفل بیومتریک',
                  onTap: () => toast(context, 'حریم خصوصی')),
              InfoRow(Icons.pie_chart_outline, 'داده‌ها و حافظه ذخیره‌سازی', sub: 'حافظه کش، دانلود خودکار',
                  onTap: () => toast(context, 'حافظه کش پاک شد')),
              InfoRow(Icons.devices_outlined, 'دستگاه‌های متصل', sub: 'لپ‌تاپ مک، نسخه وب، تبلت اندروید',
                  tag: const Tag('۳ فعال'), onTap: () => toast(context, 'دستگاه‌ها')),
            ]),
          ),
          const SectionTitle('زبان و منطقه'),
          PCard(
            child: InfoRow(Icons.translate, 'زبان اپلیکیشن', sub: 'تقویم خورشیدی و اعداد فارسی فعال',
                tag: const Tag('فارسی (پیش‌فرض)'), onTap: () => toast(context, 'زبان فارسی فعال است')),
          ),
          const SectionTitle('پشتیبانی و ارتباط'),
          PCard(
            child: DividerList([
              InfoRow(Icons.help_outline, 'راهنما و سوالات متداول', sub: 'پشتیبانی آنلاین ۲۴ ساعته',
                  onTap: () => toast(context, 'پشتیبانی')),
              InfoRow(Icons.person_add_alt, 'دعوت از دوستان', sub: 'اشتراک لینک اختصاصی عضویت',
                  onTap: () => toast(context, 'لینک دعوت کپی شد')),
            ]),
          ),
          const SizedBox(height: 14),
          PCard(
            child: InfoRow(Icons.cleaning_services_outlined, 'پاکسازی خودکار کش',
                sub: 'از اداره‌سازی فضای گوشی هر هفته',
                trailing: Switch(value: app.clean, onChanged: (_) => app.toggleClean()), onTap: app.toggleClean),
          ),
          const SizedBox(height: 14),
          PCard(
            child: InfoRow(Icons.logout, 'خروج از حساب', danger: true, onTap: () => confirmLogout(context)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text('پیام‌رسان هوشمند پیام\nنسخه ۲.۴.۰\nارتباط امن با رمزنگاری سرتاسری',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: p.mut, height: 1.7)),
          ),
        ]),
      ),
    );
  }
}
