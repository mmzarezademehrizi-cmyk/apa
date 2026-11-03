import 'dart:math';

import 'package:flutter/material.dart';

import 'auth.dart';
import 'state.dart';
import 'widgets.dart';

// ───────────────────────── کمک‌ها ─────────────────────────
class Kpi extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final IconData icon;
  const Kpi(this.label, this.value, this.sub, this.icon, {super.key, this.color = kPri});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 4, color: color),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon, size: 18, color: p.mut), const SizedBox(width: 8), Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: p.mut)))]),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2)),
            Text(sub, style: TextStyle(fontSize: 12, color: p.mut)),
          ]),
        ),
      ]),
    );
  }
}

Widget kpiGrid(List<Widget> items) => LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 560 ? 2 : 1;
      final w = (c.maxWidth - 16 * (cols - 1)) / cols;
      return Wrap(spacing: 16, runSpacing: 16, children: [for (final k in items) SizedBox(width: w, child: k)]);
    });

Widget twoCol(List<Widget> main, List<Widget> side) => LayoutBuilder(builder: (context, c) {
      Widget col(List<Widget> l) => Column(spacing: 16, crossAxisAlignment: CrossAxisAlignment.stretch, children: l);
      if (c.maxWidth >= 1000) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: col(main)),
          const SizedBox(width: 16),
          SizedBox(width: 340, child: col(side)),
        ]);
      }
      return col([...main, ...side]);
    });

Widget header(BuildContext context, String kicker, String title, String desc, List<Widget> actions) {
  final p = Pal.of(context);
  return Wrap(spacing: 16, runSpacing: 12, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.start, children: [
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (kicker.isNotEmpty) Text(kicker, style: TextStyle(fontSize: 12, color: p.chipText)),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.5)),
        if (desc.isNotEmpty) Text(desc, style: TextStyle(fontSize: 13.5, color: p.mut, height: 1.7)),
      ]),
    ),
    if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
  ]);
}

Widget cardTitle(String t, IconData i, {Widget? trailing}) => Row(children: [
      Icon(i, size: 18),
      const SizedBox(width: 8),
      Flexible(child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      if (trailing != null) ...[const SizedBox(width: 8), trailing],
    ]);

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody(this.children, {super.key});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 18), child: c),
          ]),
        ),
      );
}

// ───────────────────────── شل و منو ─────────────────────────
const _nav = [
  (Icons.grid_view, 'داشبورد اصلی'),
  (Icons.verified_user_outlined, 'مدیریت کاربران و نشان تأیید'),
  (Icons.flag_outlined, 'گزارش‌ها و تخلفات'),
  (Icons.groups_outlined, 'کانال‌ها و گروه‌ها'),
  (Icons.tune, 'تنظیمات سیستم'),
];

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: admin,
      builder: (context, _) {
        final pages = <Widget>[DashPage(), VerifyPage(), ReportsPage(), GroupsPage(), SettingsPage()];
        final page = KeyedSubtree(key: ValueKey(admin.page), child: pages[admin.page]);
        return LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 900) {
            return Scaffold(
              body: Row(children: [
                const SizedBox(width: 260, child: Sidebar()),
                Expanded(child: Column(children: [const _TopBar(), Expanded(child: page)])),
              ]),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(_nav[admin.page].$2, style: const TextStyle(fontSize: 15)),
              actions: [
                IconButton(onPressed: admin.toggleDark, icon: const Icon(Icons.dark_mode_outlined)),
                IconButton(onPressed: () => toast(context, '۳ اعلان جدید'), icon: const Icon(Icons.notifications_none)),
              ],
            ),
            drawer: const Drawer(child: Sidebar(inDrawer: true)),
            body: page,
          );
        });
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(color: p.card, border: Border(bottom: BorderSide(color: p.line))),
      child: Row(children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'جستجوی کاربر، شناسه، گزارش یا کانال...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true, fillColor: p.field, isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(onPressed: admin.toggleDark, icon: const Icon(Icons.dark_mode_outlined)),
        IconButton(onPressed: () => toast(context, '۳ اعلان جدید'), icon: const Icon(Icons.notifications_none)),
        const SizedBox(width: 10),
        const Avatar('مدیر ارشد', size: 36),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مدیر ارشد سامانه', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text('سطح دسترسی: کل', style: TextStyle(fontSize: 11, color: pillColor('g', p))),
        ]),
      ]),
    );
  }
}

class Sidebar extends StatelessWidget {
  final bool inDrawer;
  const Sidebar({super.key, this.inDrawer = false});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ListenableBuilder(listenable: admin, builder: (context, _) => Container(
      color: p.card,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: kPri, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shield_outlined, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('پیام‌رسان پیام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('پنل مدیریت و پایش هوشمند', style: TextStyle(fontSize: 11, color: p.mut)),
              ]),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(99)),
              child: Row(children: [
                const CircleAvatar(radius: 4, backgroundColor: kOk),
                const SizedBox(width: 8),
                Text('سرویس برخط و پایدار', style: TextStyle(fontSize: 12, color: p.chipText)),
              ]),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _nav.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: admin.page == i ? kPri : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      admin.go(i);
                      if (inDrawer) Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(children: [
                        Icon(_nav[i].$1, size: 20, color: admin.page == i ? Colors.white : p.mut),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_nav[i].$2,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: admin.page == i ? Colors.white : p.mut)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => confirmLogout(context),
              icon: const Icon(Icons.logout, size: 18, color: kRed),
              label: Text('خروج (${auth.masked})', style: const TextStyle(color: kRed, fontSize: 13)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('نسخه سامانه\nv3.4.2', style: TextStyle(fontSize: 12, color: p.chipText)),
                Text('موقعیت سرور\nتهران (مرکزی)', style: TextStyle(fontSize: 12, color: p.chipText)),
              ]),
            ),
          ]),
        ),
      ),
    ));
  }
}

// ───────────────────────── داشبورد ─────────────────────────
class DashPage extends StatelessWidget {
  const DashPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    Widget link(String t, String d, IconData i, int page) => PCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            cardTitle(t, i),
            const SizedBox(height: 6),
            Text(d, style: TextStyle(color: p.mut, fontSize: 13)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => admin.go(page), child: const Text('ورود')),
          ]),
        );
    return PageBody([
      header(context, '', 'داشبورد اصلی', 'نمای کلی سلامت سامانه و کارهای در انتظار مدیریت.', []),
      kpiGrid([
        Kpi('کل کاربران فعال', nf(4852100), 'همه سرورها برخط', Icons.groups_outlined),
        Kpi('تیک آبی', nf(admin.verified), '+${fa(admin.vd)} در این نشست', Icons.verified_user_outlined),
        Kpi('تأیید در انتظار', fa(admin.pending), 'نیازمند بررسی', Icons.schedule, color: kRed),
        Kpi('تخلف در صف', fa(admin.urgent), '۲۲ مورد بحرانی', Icons.flag_outlined, color: const Color(0xFFF59E0B)),
      ]),
      Wrap(spacing: 16, runSpacing: 16, children: [
        SizedBox(width: 340, child: link('تأیید هویت', '${fa(admin.queue.length)} درخواست اولویت‌دار در صف است.', Icons.verified_user_outlined, 1)),
        SizedBox(width: 340, child: link('تخلفات', 'پرونده ${fa(admin.sel)} روی میز بازرس باز است.', Icons.flag_outlined, 2)),
      ]),
    ]);
  }
}

// ───────────────────────── تأیید هویت ─────────────────────────
class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});
  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  String f = 'all', q = '';
  int pg = 1;
  static const _filters = [
    ('all', 'همه کاربران'), ('blue', 'دارای تیک آبی'), ('pending', 'در انتظار تأیید'),
    ('vip', 'کاربران VIP طلایی'), ('channel', 'کانال‌های رسمی'), ('susp', 'حساب‌های مسدود'),
  ];

  List<AUser> get _list => admin.users.where((u) {
        final okF = switch (f) {
          'blue' => ['blue', 'org'].contains(u.b),
          'pending' => u.b == 'pending',
          'vip' => u.t == 'vip',
          'channel' => u.t == 'channel',
          'susp' => u.s == 'suspended',
          _ => true,
        };
        return okF && (q.isEmpty || '${u.n} ${u.u}'.contains(q));
      }).toList();

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final all = _list;
    final pages = max(1, (all.length / 5).ceil());
    final cur = min(pg, pages);
    final rows = all.skip((cur - 1) * 5).take(5).toList();
    return PageBody([
      header(context, 'سامانه احراز هویت و مدیریت اعتبارسنجی پیام‌رسان', 'مدیریت کاربران و نشان تأیید هویت (تیک آبی)',
          'بررسی درخواست‌های تأیید هویت، اعطای نشان تیک آبی رسمی، ارزیابی مدارک ثبتی و پایش حساب‌های سازمانی و ویژه.', [
        OutlinedButton.icon(onPressed: () => toast(context, 'خروجی در حال آماده‌سازی…'), icon: const Icon(Icons.download, size: 18), label: const Text('خروجی گزارش')),
      ]),
      kpiGrid([
        Kpi('کل کاربران فعال سامانه', nf(4852100), 'رشد پایگاه کاربران در ماه‌ها: ۱۲٪+', Icons.groups_outlined),
        Kpi('کاربران دارای تیک آبی', nf(admin.verified), '۰٫۰۲۵٪ از حساب‌ها احراز شده', Icons.verified_user_outlined),
        Kpi('درخواست‌های تأیید در انتظار', fa(admin.pending), 'میانگین زمان انتظار: کمتر از ۱۸ ساعت', Icons.schedule, color: kRed),
        Kpi('گزارش‌های تخلف هویتی', fa(15), '۳ جعل هویت بحرانی در دست اقدام', Icons.warning_amber, color: const Color(0xFFF59E0B)),
      ]),
      twoCol([
        PCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            cardTitle('صف بررسی فوری درخواست‌های تأیید هویت', Icons.bolt, trailing: Pill('${fa(admin.queue.length)} اولویت اول', 'b')),
            const SizedBox(height: 12),
            if (admin.queue.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('صف خالی است 🎉', style: TextStyle(color: p.mut)))),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (var i = 0; i < admin.queue.length; i++)
                SizedBox(
                  width: 240,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Avatar(admin.queue[i].n, size: 44),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(admin.queue[i].n, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Directionality(textDirection: TextDirection.ltr, child: Text('@${admin.queue[i].u}', style: TextStyle(fontSize: 12, color: p.mut))),
                        ])),
                      ]),
                      const SizedBox(height: 6),
                      Text(admin.queue[i].d, style: TextStyle(fontSize: 12, color: p.mut)),
                      const SizedBox(height: 6),
                      Pill(admin.queue[i].doc, 'g', icon: Icons.check),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: FilledButton(onPressed: () { final n = admin.queue[i].n; admin.qDecide(i, true); toast(context, 'تیک آبی برای $n اعطا شد'); }, child: const Text('اعطای تیک آبی'))),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(onPressed: () { admin.qDecide(i, false); toast(context, 'درخواست رد شد'); }, icon: const Icon(Icons.close, size: 18)),
                      ]),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
        PCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            cardTitle('بانک جامع کاربران سامانه', Icons.groups_outlined),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() { q = v.trim(); pg = 1; }),
              decoration: InputDecoration(
                hintText: 'فیلتر نام یا شناسه...', filled: true, fillColor: p.field, isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final x in _filters)
                ChoiceChip(
                  selected: f == x.$1,
                  onSelected: (_) => setState(() { f = x.$1; pg = 1; }),
                  showCheckmark: false,
                  shape: const StadiumBorder(side: BorderSide.none),
                  backgroundColor: p.chip, selectedColor: kPri,
                  labelStyle: TextStyle(fontSize: 12.5, color: f == x.$1 ? Colors.white : p.chipText),
                  label: Text(x.$2),
                ),
            ]),
            const SizedBox(height: 10),
            if (rows.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('کاربری پیدا نشد', style: TextStyle(color: p.mut)))),
            for (final u in rows) _userRow(context, u, p),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Text('نمایش ${fa(rows.length)} از ${all.length == admin.users.length ? nf(4852100) : fa(all.length)} حساب', style: TextStyle(fontSize: 12.5, color: p.mut))),
              Row(children: [
                IconButton(onPressed: cur > 1 ? () => setState(() => pg = cur - 1) : null, icon: const Icon(Icons.chevron_right)),
                Text('${fa(cur)} / ${fa(pages)}'),
                IconButton(onPressed: cur < pages ? () => setState(() => pg = cur + 1) : null, icon: const Icon(Icons.chevron_left)),
              ]),
            ]),
          ]),
        ),
      ], [
        const _GrantForm(),
        PCard(
          padding: const EdgeInsets.all(18),
          child: Container(
            color: p.chip.withOpacity(0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              cardTitle('قوانین نشان تأیید پیام‌رسان پیام', Icons.shield_outlined),
              const SizedBox(height: 8),
              Text('اعطای نشان تیک آبی نیازمند حداقل یکی از مدارک هویتی معتبر، انطباق نام کاربری با مستندات رسمی و تأیید عدم سوءاستفاده است. تغییر نام کاربری پس از اخذ تیک آبی نیازمند بررسی مجدد خواهد بود.',
                  style: TextStyle(fontSize: 12.5, color: p.mut, height: 1.8)),
            ]),
          ),
        ),
      ]),
    ]);
  }

  Widget _userRow(BuildContext context, AUser u, Pal p) {
    final (bl, bk) = badgeInfo[u.b]!;
    final granted = u.b == 'blue' || u.b == 'org' || u.b == 'gold';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(u.n, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.n, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            Directionality(textDirection: TextDirection.ltr, child: Text('@${u.u}', style: TextStyle(fontSize: 11.5, color: p.mut))),
          ])),
          Pill(u.s == 'active' ? 'فعال' : 'مسدود', u.s == 'active' ? 'g' : 'r'),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Pill(bl, bk),
          Text(typeLabel[u.t]!, style: TextStyle(fontSize: 12, color: p.mut)),
          Text('عضویت: ${u.d}', style: TextStyle(fontSize: 12, color: p.mut)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          granted
              ? OutlinedButton.icon(onPressed: () { admin.setBadge(u.u, 'none'); toast(context, 'نشان لغو شد'); }, icon: const Icon(Icons.undo, size: 16), label: const Text('لغو نشان'))
              : FilledButton.icon(onPressed: () { admin.setBadge(u.u, 'blue'); toast(context, 'نشان تأیید اعطا شد'); }, icon: const Icon(Icons.check, size: 16), label: const Text('اعطای نشان')),
          const SizedBox(width: 6),
          IconButton(tooltip: u.s == 'active' ? 'تعلیق' : 'رفع تعلیق', onPressed: () => admin.toggleSuspend(u.u), icon: Icon(Icons.block, color: u.s == 'active' ? p.mut : kRed)),
        ]),
      ]),
    );
  }
}

class _GrantForm extends StatefulWidget {
  const _GrantForm();
  @override
  State<_GrantForm> createState() => _GrantFormState();
}

class _GrantFormState extends State<_GrantForm> {
  final _u = TextEditingController(), _note = TextEditingController();
  String b = 'blue';
  bool perm = true;

  @override
  void dispose() { _u.dispose(); _note.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    Widget opt(String k, IconData i, String t, String s) => InkWell(
          onTap: () => setState(() => b = k),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: b == k ? p.chip : null,
              border: Border.all(color: b == k ? kPri : p.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(b == k ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: b == k ? kPri : p.mut),
              const SizedBox(width: 8),
              Icon(i, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(s, style: TextStyle(fontSize: 11.5, color: p.mut)),
              ])),
            ]),
          ),
        );
    InputDecoration dec(String h) => InputDecoration(
        hintText: h, filled: true, fillColor: p.field,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        cardTitle('اعطای مستقیم نشان تأیید', Icons.verified_user_outlined),
        const SizedBox(height: 12),
        const Text('شناسه یا نام کاربری مقصد', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: _u, textDirection: TextDirection.ltr, decoration: dec('مثال: dr_kazemi')),
        const SizedBox(height: 12),
        const Text('نوع نشان اعطایی', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        opt('blue', Icons.verified_user_outlined, 'تیک آبی رسمی', 'افراد سرشناس و مشاغل'),
        opt('org', Icons.apartment, 'نشان سازمانی خاکستری', 'نهادها و سازمان‌ها'),
        opt('gold', Icons.star_outline, 'نشان طلایی ویژه (VIP)', 'حامیان و اعضای ویژه'),
        const SizedBox(height: 4),
        const Text('مستندات و توضیحات مدیر تأییدکننده', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: _note, maxLines: 3, decoration: dec('ذکر شماره مصوبه، استعلام نظام مهندسی/پزشکی ...')),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('اعتبار دائمی نشان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Switch(value: perm, onChanged: (v) => setState(() => perm = v)),
        ]),
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: () {
            final u = _u.text.trim().replaceFirst('@', '');
            if (u.isEmpty) { toast(context, 'شناسه کاربر را وارد کنید'); return; }
            admin.grant(u, b);
            _u.clear(); _note.clear();
            toast(context, 'نشان تأیید برای @$u ثبت شد');
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('ثبت رسمی و اعطای فوری نشان تأیید'),
        ),
      ]),
    );
  }
}

// ───────────────────────── گزارش‌ها و تخلفات ─────────────────────────
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String cf = 'all', sf = 'all';

  @override
  Widget build(BuildContext context) {
    final done = admin.doneView && admin.last != null;
    return PageBody(done ? _doneChildren(context) : _benchChildren(context));
  }

  Widget _table(BuildContext context, Pal p) {
    final all = admin.cases.where((c) => (cf == 'all' || c.cat == cf) && (sf == 'all' || c.sev == sf || (sf == 'crit' && c.sev == 'high'))).toList();
    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        cardTitle('صف مدیریت گزارش‌ها و تخلفات برخط', Icons.flag_outlined),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final c in cats) _chip(p, '${c.$2} (${fa(c.$3)})', cf == c.$1, () => setState(() => cf = c.$1)),
        ]),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final s in const [('all', 'همه'), ('crit', 'بحرانی'), ('mid', 'متوسط'), ('low', 'عادی')])
            _chip(p, s.$2, sf == s.$1, () => setState(() => sf = s.$1)),
        ]),
        const SizedBox(height: 8),
        if (all.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('موردی پیدا نشد', style: TextStyle(color: p.mut)))),
        for (final c in all)
          InkWell(
            onTap: () => admin.selectCase(c.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: admin.sel == c.id ? kPri.withOpacity(.07) : null,
                border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Directionality(textDirection: TextDirection.ltr, child: Text('REP-#${fa(c.id)}', style: const TextStyle(color: kPri, fontWeight: FontWeight.w700))),
                  const Spacer(),
                  Pill('${sevInfo[c.sev]!.$1} (${fa(c.sc)}٪)', sevInfo[c.sev]!.$2),
                  const SizedBox(width: 6),
                  Pill(statusInfo[c.st]!.$1, statusInfo[c.st]!.$2),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Avatar(c.n, size: 34),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.n, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Directionality(textDirection: TextDirection.ltr, child: Text('@${c.u}', style: TextStyle(fontSize: 11.5, color: p.mut))),
                  ])),
                ]),
                const SizedBox(height: 6),
                Text(c.cl, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.sev == 'crit' ? kRed : null)),
                Text('${c.src} · ${c.tm}', style: TextStyle(fontSize: 12, color: p.mut)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _chip(Pal p, String t, bool on, VoidCallback f) => ChoiceChip(
        selected: on, onSelected: (_) => f(), showCheckmark: false,
        shape: const StadiumBorder(side: BorderSide.none),
        backgroundColor: p.chip, selectedColor: kPri,
        labelStyle: TextStyle(fontSize: 12.5, color: on ? Colors.white : p.chipText), label: Text(t));

  List<Widget> _benchChildren(BuildContext context) {
    final p = Pal.of(context);
    final c = admin.current;
    final closed = ['banned', 'rej'].contains(c.st);
    final sample = switch (c.cat) {
      'phish' => 'سلام دوست عزیز! جشنواره ویژه پیام آغاز شد. برای دریافت هدیه ۱۰ میلیون تومانی سریعاً روی پیوند زیر کلیک و کیف پول خود را احراز کنید:',
      'imp' => 'سلام، من از تیم پشتیبانی پیام هستم. برای جلوگیری از مسدود شدن حساب، کد تأیید پیامک‌شده را همین‌جا ارسال کنید.',
      'harass' => 'متن تهدیدآمیز و توهین‌آمیز ارسال‌شده به چند کاربر (جزئیات در پرونده حقوقی).',
      _ => 'پیام تبلیغاتی انبوه و تکراری ارسال‌شده در بیش از ۱۰ گروه.',
    };
    final next = admin.cases.where((x) => x.id != c.id && ['wait', 'legal', 'desk'].contains(x.st)).take(3).toList();
    final a = min(99.9, c.sc.toDouble()), b = max(5.0, c.sc - 7.0), l = c.cat == 'phish' ? 0.0 : (100 - c.sc / 2);
    Widget meter(String t, double v, Color col) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Text(t, style: const TextStyle(fontSize: 12.5))),
              Text('${fa(v.toStringAsFixed(1)).replaceAll('.', '٫')}٪', style: TextStyle(fontWeight: FontWeight.w700, color: col, fontSize: 12.5)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: v / 100, minHeight: 8, color: col, backgroundColor: p.field)),
          ]),
        );
    return [
      header(context, 'سامانه رسیدگی انضباطی و امنیت کاربران', 'مرکز پایش، گزارش‌ها و رسیدگی به تخلفات کاربران',
          'بررسی گزارش‌های دریافتی، تشخیص خودکار نقض قوانین، اقدام انضباطی و مسدودسازی متخلفان با نظارت دوگانه هوش مصنوعی و هیئت بازرسی.', [
        OutlinedButton.icon(onPressed: () => toast(context, 'خروجی در حال آماده‌سازی…'), icon: const Icon(Icons.download, size: 18), label: const Text('خروجی گزارش تخلفات')),
      ]),
      kpiGrid([
        Kpi('گزارش‌های نیازمند اقدام', '${fa(admin.urgent)} مورد', '۲۲ مورد با اولویت بحرانی', Icons.notifications_none, color: kRed),
        Kpi('تخلفات مسدودشده امروز', fa(admin.banned), 'حساب و کانال', Icons.block),
        Kpi('میانگین زمان پاسخگویی', '${fa(12)} دقیقه', 'هدف: کمتر از ۱۵ دقیقه', Icons.schedule),
        Kpi('نرخ گزارش‌های معتبر', '${fa('۸۹٫۴')}٪', 'دقت بازخورد کاربران', Icons.check_circle_outline, color: kOk),
      ]),
      twoCol([
        PCard(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(border: BorderDirectional(start: BorderSide(color: kRed, width: 5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('میز بازرس ارشد · پرونده جاری:', style: TextStyle(fontWeight: FontWeight.w700)),
                Directionality(textDirection: TextDirection.ltr, child: Text('REP-#${fa(c.id)}', style: const TextStyle(color: kPri, fontWeight: FontWeight.w700))),
                Pill('اولویت: ${sevInfo[c.sev]!.$1}', sevInfo[c.sev]!.$2, icon: Icons.warning_amber),
                Pill(statusInfo[c.st]!.$1, statusInfo[c.st]!.$2),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Avatar(c.n, size: 52),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.n, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Directionality(textDirection: TextDirection.ltr, child: Text('@${c.u}', style: TextStyle(fontSize: 12.5, color: p.mut))),
                    Text('دریافت اولین گزارش: ${c.tm}', style: TextStyle(fontSize: 12, color: p.mut)),
                  ])),
                  Column(children: [Pill('احتمال تخلف ${fa(c.sc)}٪', sevInfo[c.sev]!.$2), Text(c.src, style: TextStyle(fontSize: 11.5, color: p.mut))]),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('محتوای پیام مشکوک و شواهد ارسالی', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(sample, style: const TextStyle(fontSize: 13.5, height: 1.8)),
                  if (c.cat == 'phish') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: kRed.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
                      child: const Directionality(textDirection: TextDirection.ltr, child: Text('https://free-crypto-payam-gift.net/claim-auth', style: TextStyle(color: kRed, fontSize: 12.5))),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(onPressed: closed ? null : () { admin.act('rej'); toast(context, 'پرونده ردشد'); }, icon: const Icon(Icons.close, size: 16), label: const Text('ردگزارش (عدم تخلف)')),
                FilledButton.tonalIcon(onPressed: closed ? null : () { admin.act('warn'); toast(context, 'پیام حذف و اخطار اول ثبت شد'); }, icon: const Icon(Icons.description_outlined, size: 16), label: const Text('حذف پیام و اخطار اول')),
                FilledButton.tonalIcon(onPressed: closed ? null : () { admin.act('restr'); toast(context, 'چت کاربر به مدت ۷ روز محدود شد'); }, icon: const Icon(Icons.lock_clock, size: 16), label: const Text('محدودیت چت (۷ روز)')),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kRed),
                  onPressed: closed ? null : () => _banDialog(context),
                  icon: const Icon(Icons.block, size: 16), label: const Text('مسدودسازی کامل و بن IP (دائمی)')),
              ]),
            ]),
          ),
        ),
      ], [
        PCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            cardTitle('تحلیل هوشمند رادار سلامت', Icons.bolt, trailing: const Pill('مدل v4.8', 'g')),
            const SizedBox(height: 12),
            meter('تشخیص فیشینگ و سرقت داده', a, kRed),
            meter('شباهت به الگوهای اسپم هماهنگ', b, kPri),
            meter('اعتبار دامنه لینک ارسالی', l, kOk),
            Center(child: SizedBox(width: 180, height: 180, child: CustomPaint(painter: _Radar(c.sc.toDouble(), p.line)))),
          ]),
        ),
        PCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            cardTitle('موارد فوری بعدی در صف', Icons.list_alt),
            const SizedBox(height: 8),
            if (next.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Center(child: Text('موردی نیست', style: TextStyle(color: p.mut)))),
            for (final x in next)
              InkWell(
                onTap: () => admin.selectCase(x.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(x.cl, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Directionality(textDirection: TextDirection.ltr, child: Text('@${x.u}', style: TextStyle(fontSize: 11.5, color: p.mut))),
                    ])),
                    Pill(sevInfo[x.sev]!.$1, sevInfo[x.sev]!.$2),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
      _table(context, p),
    ];
  }

  List<Widget> _doneChildren(BuildContext context) {
    final p = Pal.of(context);
    final L = admin.last!;
    final nxt = admin.cases.where((x) => ['wait', 'legal', 'desk'].contains(x.st)).firstOrNull;
    final steps = [
      if (L.sess) ('ردیابی و ابطال نشست‌های فعال (Revoke All Sessions)', '۴ نشست فعال اندروید، وب و ویندوز با ابطال توکن JWT خارج شدند.'),
      if (L.purge) ('پالایش دسته‌جمعی لینک‌ها و پیام‌های ارسالی', 'دامنه فیشینگ در فایروال محتوا Blacklist شد و پیام‌های حاوی آن از تمام کانال‌ها حذف شد.'),
      if (L.hw) ('مسدودسازی زیرساخت سخت‌افزاری و شماره موبایل', 'IP و شناسه دستگاه به فهرست سیاه ملی الحاق شد و ثبت‌نام مجدد ممکن نیست.'),
    ];
    return [
      PCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(radius: 28, backgroundColor: kOk, child: Icon(Icons.check, color: Colors.white, size: 30)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('عملیات مسدودسازی با موفقیت اعمال و نهایی شد', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.5)),
              Text('پرونده REP-#${fa(L.id)} · ${L.time}', style: TextStyle(color: p.mut, fontSize: 12.5)),
            ])),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (L.sess) const Pill('سلب مالکیت قطعی حساب کاربری', 'g', icon: Icons.check),
            if (L.hw) const Pill('مسدودسازی IP و شناسه سخت‌افزار', 'g', icon: Icons.check),
            if (L.purge) const Pill('حذف پیام‌های فیشینگ از شبکه', 'g', icon: Icons.check),
            if (L.legal) const Pill('ارجاع به پلیس فتا و قوه قضاییه', 'g', icon: Icons.check),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (nxt != null) FilledButton.icon(onPressed: () { admin.selectCase(nxt.id); }, icon: const Icon(Icons.arrow_back, size: 16), label: const Text('بررسی پرونده بعدی در صف')),
            OutlinedButton.icon(onPressed: () => toast(context, 'صورتجلسه در حال آماده‌سازی…'), icon: const Icon(Icons.description_outlined, size: 16), label: const Text('دریافت صورتجلسه PDF')),
            TextButton(onPressed: admin.backToBench, child: const Text('بازگشت به میز کار')),
          ]),
        ]),
      ),
      kpiGrid([
        Kpi('پرونده‌های فوری در صف', fa(admin.urgent), 'کاهش از ۸۴ مورد', Icons.notifications_none, color: kRed),
        Kpi('تخلفات مسدودشده امروز', fa(admin.banned), '+۱ پرونده اخیر', Icons.block),
        Kpi('میانگین زمان بررسی و اقدام', '${fa('۳٫۴')} دقیقه', 'بهبود ۱۸٪', Icons.timer_outlined),
        Kpi('پاکسازی خودکار و سلامت شبکه', '${fa('۹۹٫۸')}٪', 'پایدار', Icons.cleaning_services_outlined, color: kOk),
      ]),
      PCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          cardTitle('خلاصه صورتجلسه امنیتی پرونده مختومه', Icons.description_outlined, trailing: const Pill('مختومه قطعی', 'g')),
          const SizedBox(height: 10),
          Text('کاربر: @${L.u} (مسدود دائم)', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('مبنای قانونی: ${L.basis}', style: TextStyle(fontSize: 13, color: p.mut)),
          Text('بازرس: امین سهرابی (مدیر ارشد پیام‌رسان) · Tier-3 Executive Admin', style: TextStyle(fontSize: 13, color: p.mut)),
          const SizedBox(height: 12),
          cardTitle('گام‌های فنی اعمال‌شده در فرایند پالایش', Icons.history),
          const SizedBox(height: 8),
          for (final s in steps)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle, color: kOk, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(s.$2, style: TextStyle(fontSize: 12.5, color: p.mut, height: 1.7)),
                ])),
              ]),
            ),
          if (L.note.isNotEmpty) Text('یادداشت بازرس: ${L.note}', style: TextStyle(fontSize: 12.5, color: p.mut)),
        ]),
      ),
      _table(context, p),
    ];
  }

  Future<void> _banDialog(BuildContext context) async {
    final c = admin.current;
    const bases = [
      ('ماده ۷۴۱ قانون جرایم رایانه‌ای', 'کلاهبرداری مرتبط با رایانه؛ نقض امنیت داده‌ها و سرقت اطلاعات اعتباری'),
      ('ماده ۷۴۶ قانون جرایم رایانه‌ای', 'جعل سامانه‌های رسمی و ایجاد صفحات فیشینگ'),
      ('بند ۲ شرایط و ضوابط عمومی', 'ارسال انبوه و بدافزار یا بهره‌برداری غیرمجاز'),
      ('نقض حریم خصوصی و فریب مالی', 'تلاش سازمان‌یافته برای تصاحب دارایی دیجیتال'),
    ];
    var basis = 0;
    final scope = [true, true, true, true];
    const scopeLabels = [
      'مسدودسازی دائم حساب کاربری و سلب مالکیت شناسه', 'بن دائمی IP و شناسه سخت‌افزار دستگاه‌ها',
      'حذف خودکار تمام پیام‌ها و لینک‌های آلوده', 'ارسال خودکار مستندات به پلیس فتا و مراجع قضایی',
    ];
    final note = TextEditingController(text: 'بر اساس بررسی کارشناس امنیت سایبری و الگوریتم‌های هوش مصنوعی، تخلف ثابت شده و اقدام عاجل مسدودسازی قطعی اعمال می‌گردد.');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final p = Pal.of(ctx);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            scrollable: true,
            title: Text('تأیید نهایی مسدودسازی · @${c.u}', style: const TextStyle(fontSize: 17)),
            content: SizedBox(
              width: 560,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('مستندات و دلایل قانونی تخلف', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                for (var i = 0; i < bases.length; i++)
                  InkWell(
                    onTap: () => setS(() => basis = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: basis == i ? p.chip : null,
                        border: Border.all(color: basis == i ? kPri : p.line), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(basis == i ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: basis == i ? kPri : p.mut),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(bases[i].$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(bases[i].$2, style: TextStyle(fontSize: 11.5, color: p.mut)),
                        ])),
                      ]),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text('دامنه و شیوه اعمال محدودیت', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                for (var i = 0; i < 4; i++)
                  SwitchListTile(
                    dense: true, contentPadding: EdgeInsets.zero,
                    title: Text(scopeLabels[i], style: const TextStyle(fontSize: 13)),
                    value: scope[i], onChanged: (v) => setS(() => scope[i] = v)),
                const SizedBox(height: 6),
                TextField(
                  controller: note, maxLines: 3,
                  decoration: InputDecoration(labelText: 'یادداشت بازرس', filled: true, fillColor: p.field,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 8),
                const Text('توجه: این اقدام غیرقابل بازگشت بوده و کلیه نشست‌های فعال کاربر بلافاصله خاتمه می‌یابد.', style: TextStyle(color: kRed, fontSize: 12)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف و بازگشت به میز کار')),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kRed),
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.lock, size: 16), label: const Text('تأیید نهایی و مسدودسازی ابدی')),
            ],
          ),
        );
      }),
    );
    if (ok == true) {
      final t = fa(DateTime.now().toString().substring(11, 19));
      admin.ban(BanInfo(c.id, c.u, t, bases[basis].$1, note.text, scope[0], scope[1], scope[2], scope[3]));
    }
  }
}

class _Radar extends CustomPainter {
  final double score;
  final Color grid;
  _Radar(this.score, this.grid);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2;
    final line = Paint()..color = grid..style = PaintingStyle.stroke;
    for (final k in [1.0, .68, .38]) {
      canvas.drawCircle(c, r * k * .9, line);
    }
    final v = [score, max(10, score - 9), max(10, score - 20), max(10, score - 5), max(10, score - 15)];
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final pt = Offset(c.dx + r * .9 * v[i] / 100 * cos(a), c.dy + r * .9 * v[i] / 100 * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = kPri.withOpacity(.25));
    canvas.drawPath(path, Paint()..color = kPri..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_Radar o) => o.score != score || o.grid != grid;
}

// ───────────────────────── کانال‌ها و تنظیمات ─────────────────────────
class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('کانال تکنولوژی و هوش مصنوعی', 'کانال', '۱۲٬۸۰۰', true),
      ('تیم طراحی محصول', 'گروه', '۱۱', true),
      ('جشنواره ارز دیجیتال', 'گروه', '۴٬۲۱۰', false),
      ('کانال اخبار و تکنولوژی', 'کانال', '۹۸٬۰۰۰', true),
    ];
    return PageBody([
      header(context, '', 'کانال‌ها و گروه‌ها', 'فهرست کانال‌ها و گروه‌های پرمخاطب سامانه.', []),
      PCard(
        child: DividerList([
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Avatar(r.$1),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${r.$2} · ${r.$3} عضو', style: TextStyle(fontSize: 12.5, color: Pal.of(context).mut)),
                ])),
                Pill(r.$4 ? 'فعال' : 'تحت بررسی', r.$4 ? 'g' : 'y'),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool ai = true, mail = true;
  @override
  Widget build(BuildContext context) {
    return PageBody([
      header(context, '', 'تنظیمات سیستم', '', []),
      PCard(
        child: DividerList([
          InfoRow(Icons.dark_mode_outlined, 'تم تیره', trailing: Switch(value: admin.dark, onChanged: (_) => admin.toggleDark()), onTap: admin.toggleDark),
          InfoRow(Icons.smart_toy_outlined, 'اقدام خودکار هوش مصنوعی (Active AI Guard)', trailing: Switch(value: ai, onChanged: (v) => setState(() => ai = v)), onTap: () => setState(() => ai = !ai)),
          InfoRow(Icons.mail_outline, 'اعلان بحرانی به ایمیل مدیر', trailing: Switch(value: mail, onChanged: (v) => setState(() => mail = v)), onTap: () => setState(() => mail = !mail)),
        ]),
      ),
    ]);
  }
}
