import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state.dart';
import 'widgets.dart';

// ───────────────────────── صفحهٔ چت ─────────────────────────
class ChatScreen extends StatefulWidget {
  final String id;
  const ChatScreen(this.id, {super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  int _count = -1;

  @override
  void initState() {
    super.initState();
    app.openId = widget.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => app.markRead(widget.id));
  }

  @override
  void dispose() {
    app.openId = null;
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final t = _scroll.position.maxScrollExtent;
      animate
          ? _scroll.animateTo(t, duration: const Duration(milliseconds: 220), curve: Curves.easeOut)
          : _scroll.jumpTo(t);
    });
  }

  void _send() {
    final t = _ctrl.text;
    if (t.trim().isEmpty) return;
    app.send(widget.id, t);
    _ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final c = app.chat(widget.id);
        if (c == null) return const Scaffold(body: SizedBox());
        final person = people[c.id];
        final typing = app.typingId == c.id;
        if (_count != c.msgs.length + (typing ? 1 : 0)) {
          final first = _count == -1;
          _count = c.msgs.length + (typing ? 1 : 0);
          _toBottom(animate: !first);
        }
        final status = c.type == ChatType.personal
            ? (typing ? 'در حال نوشتن…' : person?.online == true ? 'آنلاین' : 'به‌تازگی آنلاین بوده')
            : c.type == ChatType.group ? '${fa(c.msgs.length + 8)} عضو' : '${fa(12400)} دنبال‌کننده';
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: InkWell(
              onTap: c.type == ChatType.personal && person != null
                  ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(c.id)))
                  : null,
              child: Row(children: [
                Avatar(c.name, size: 40, online: person?.online == true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                      if (c.verified || person?.verified == true)
                        const Padding(padding: EdgeInsetsDirectional.only(start: 4), child: VerifiedBadge()),
                    ]),
                    Text(status,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
                            color: person?.online == true || typing ? kOk : p.mut)),
                  ]),
                ),
              ]),
            ),
            actions: [
              IconButton.filledTonal(
                  onPressed: () => startCall(context, c.name, true), icon: const Icon(Icons.videocam_outlined, size: 20)),
              IconButton.filledTonal(
                  onPressed: () => startCall(context, c.name, false), icon: const Icon(Icons.call_outlined, size: 20)),
              const SizedBox(width: 6),
            ],
          ),
          body: Column(children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(99)),
                      child: Text('امروز', style: TextStyle(fontSize: 12, color: p.chipText)),
                    ),
                  ),
                  for (final m in c.msgs) Padding(padding: const EdgeInsets.only(bottom: 8), child: _Bubble(c, m)),
                  if (typing)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${c.name.split(' ').first} در حال نوشتن…', style: TextStyle(fontSize: 12, color: p.chipText)),
                          const SizedBox(width: 6),
                          const _Dots(),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            _composer(context, c, p),
          ]),
        );
      },
    );
  }

  Widget _composer(BuildContext context, Chat c, Pal p) {
    Widget note(String t) => Container(
        width: double.infinity,
        color: p.card,
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(color: p.mut, fontSize: 13)));
    if (c.type == ChatType.channel) return note('فقط ادمین‌ها می‌توانند پیام ارسال کنند');
    if (app.blocked.contains(c.id)) return note('این مخاطب را مسدود کرده‌اید');
    final has = _ctrl.text.trim().isNotEmpty;
    return Container(
      color: p.card,
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(99)),
            child: Row(children: [
              IconButton(onPressed: () => toast(context, 'دوربین'), icon: Icon(Icons.photo_camera_outlined, color: p.mut, size: 22)),
              IconButton(onPressed: () => toast(context, 'پیوست'), icon: Icon(Icons.attach_file, color: p.mut, size: 22)),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(hintText: 'پیام خود را بنویسید…', border: InputBorder.none, isDense: true),
                ),
              ),
              IconButton(
                  onPressed: () { _ctrl.text += '😊'; setState(() {}); },
                  icon: Icon(Icons.emoji_emotions_outlined, color: p.mut, size: 22)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: kPri,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: kPri.withOpacity(.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: has ? _send : () => toast(context, 'برای ضبط پیام صوتی نگه دارید'),
            child: SizedBox(width: 46, height: 46, child: Icon(has ? Icons.send : Icons.mic, color: Colors.white, size: 22)),
          ),
        ),
      ]),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() { _a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                  color: kPri.withOpacity(((_a.value * 3 - i) % 3) < 1 ? 1 : .3), shape: BoxShape.circle),
            ),
        ]),
      );
}

class _Bubble extends StatelessWidget {
  final Chat chat;
  final Msg m;
  const _Bubble(this.chat, this.m);

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mine = m.mine;
    final fg = mine ? Colors.white : p.ink;
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(20),
      topEnd: const Radius.circular(20),
      bottomStart: Radius.circular(mine ? 20 : 4),
      bottomEnd: Radius.circular(mine ? 4 : 20),
    );
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .82),
        child: GestureDetector(
          onDoubleTap: () => app.toggleReact(m),
          child: Padding(
            padding: EdgeInsets.only(bottom: m.react != null ? 12 : 0),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: mine ? kPri : p.card,
                  borderRadius: radius,
                  border: mine ? null : Border.all(color: p.line),
                  boxShadow: mine ? null : const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  if (m.replyText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPri.withOpacity(.1),
                            border: const BorderDirectional(start: BorderSide(color: kPri, width: 3)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.replyName ?? '', style: const TextStyle(color: kPri, fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(m.replyText!, style: TextStyle(color: p.mut, fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                  if (chat.type == ChatType.group && !mine && m.who != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(m.who!, style: const TextStyle(color: kPri, fontSize: 12, fontWeight: FontWeight.w700))),
                  if (m.file != null)
                    Container(
                      width: 220,
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFFDA4AF)],
                            begin: Alignment.topRight, end: Alignment.bottomLeft),
                      ),
                      alignment: AlignmentDirectional.bottomStart,
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0x990F172A), borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.attach_file, size: 13, color: Colors.white),
                          Text(m.file!, textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ]),
                      ),
                    ),
                  if (m.voiceSec != null) VoiceBubble(seconds: m.voiceSec!, mine: mine, seed: m.time.hashCode),
                  if (m.text.isNotEmpty) Text(m.text, style: TextStyle(color: fg, fontSize: 15, height: 1.7)),
                  const SizedBox(height: 2),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(m.time, style: TextStyle(fontSize: 11, color: mine ? const Color(0xFFBFDBFE) : p.mut)),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(m.seen ? Icons.done_all : Icons.done, size: 15, color: m.seen ? const Color(0xFF6EE7B7) : Colors.white),
                    ],
                  ]),
                ]),
              ),
              if (m.react != null)
                PositionedDirectional(
                  bottom: -12,
                  end: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                        color: p.card, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.line)),
                    child: Text('${m.rc > 1 ? '${fa(m.rc)} ' : ''}${m.react}', style: const TextStyle(fontSize: 12)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class VoiceBubble extends StatefulWidget {
  final int seconds, seed;
  final bool mine;
  const VoiceBubble({super.key, required this.seconds, required this.mine, required this.seed});
  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) { if (s == AnimationStatus.completed) setState(() {}); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _toggle() {
    if (_c.isAnimating) { _c.stop(); setState(() {}); return; }
    _c.duration = Duration(milliseconds: (widget.seconds * 1000 / _speed).round());
    _c.forward(from: _c.value >= 1 ? 0 : _c.value);
  }

  void _cycle() {
    _speed = _speed == 1 ? 1.5 : _speed == 1.5 ? 2 : 1;
    final v = _c.value;
    _c.duration = Duration(milliseconds: (widget.seconds * 1000 / _speed).round());
    if (_c.isAnimating) _c.forward(from: v);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mine = widget.mine;
    final on = mine ? Colors.white : kPri;
    final off = (mine ? Colors.white : p.mut).withOpacity(.35);
    const n = 28;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 230,
        child: Row(children: [
          Material(
            color: mine ? Colors.white : kPri,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: SizedBox(
                  width: 40, height: 40,
                  child: Icon(_c.isAnimating ? Icons.pause : Icons.play_arrow, color: mine ? kPri : Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 30,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var i = 0; i < n; i++)
                  Container(
                    width: 3,
                    height: 6 + (sin(i * 1.7 + widget.seed % 7)).abs() * 22,
                    decoration: BoxDecoration(
                        color: i / n < _c.value ? on : off, borderRadius: BorderRadius.circular(2)),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _cycle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(99)),
              child: Text('${fa(_speed == 1.5 ? '1.5' : _speed.toInt()).replaceAll('.', '٫')}×',
                  style: TextStyle(fontSize: 11, color: p.chipText, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── پروفایل مخاطب ─────────────────────────
class ProfileScreen extends StatefulWidget {
  final String id;
  const ProfileScreen(this.id, {super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int tab = 0;
  static const _tabs = [['عکس و ویدیو', '۱۲۴'], ['فایل‌ها', '۱۸'], ['لینک‌ها', '۴۲'], ['صداها', '۹']];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final x = people[widget.id]!;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final muted = app.muted.contains(x.id), blocked = app.blocked.contains(x.id);
        Widget action(IconData i, String t, VoidCallback f, {bool primary = false, bool hot = false}) => Expanded(
              child: GestureDetector(
                onTap: f,
                child: PCard(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(children: [
                    CircleAvatar(
                        radius: 23,
                        backgroundColor: hot ? kRed : primary ? kPri : p.chip,
                        child: Icon(i, color: (hot || primary) ? Colors.white : p.chipText, size: 22)),
                    const SizedBox(height: 6),
                    Text(t, style: const TextStyle(fontSize: 12)),
                  ]),
                ),
              ),
            );
        return Scaffold(
          appBar: AppBar(title: const Text('پروفایل مخاطب', style: TextStyle(fontSize: 17))),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            PCard(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              child: Column(children: [
                Avatar(x.name, size: 110, online: x.online),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(x.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  if (x.verified) const Padding(padding: EdgeInsetsDirectional.only(start: 6), child: VerifiedBadge(size: 20)),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  _pill(p, '@${x.user}'),
                  _pill(p, x.phone),
                ]),
                if (x.bio.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(x.bio, style: TextStyle(color: p.mut))),
              ]),
            ),
            const SizedBox(height: 12),
            Row(spacing: 10, children: [
              action(Icons.chat_bubble, 'پیام', () => Navigator.of(context).pop(), primary: true),
              action(Icons.call_outlined, 'تماس صوتی', () => startCall(context, x.name, false)),
              action(Icons.videocam_outlined, 'تصویری', () => startCall(context, x.name, true)),
              action(Icons.notifications_off_outlined, muted ? 'باصدا' : 'بی‌صدا', () => app.toggleMute(x.id), hot: muted),
            ]),
            const SizedBox(height: 12),
            PCard(
              child: InfoRow(Icons.notifications_none, 'اعلان‌ها و صداها',
                  sub: 'پخش صدا و هشدار پیام‌های دریافتی',
                  trailing: Switch(value: !muted, onChanged: (_) => app.toggleMute(x.id)),
                  onTap: () => app.toggleMute(x.id)),
            ),
            const SizedBox(height: 12),
            PCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('رسانه‌ها و فایل‌های مشترک', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          selected: tab == i,
                          onSelected: (_) => setState(() => tab = i),
                          showCheckmark: false,
                          shape: const StadiumBorder(side: BorderSide.none),
                          backgroundColor: p.chip,
                          selectedColor: kPri,
                          labelStyle: TextStyle(fontSize: 13, color: tab == i ? Colors.white : p.chipText),
                          label: Text('${_tabs[i][0]} (${_tabs[i][1]})'),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 10),
                Row(spacing: 8, children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(colors: [
                              HSLColor.fromAHSL(1, 215.0 + i * 25 + tab * 10, .8, .62).toColor(),
                              HSLColor.fromAHSL(1, 240.0 + i * 20 + tab * 10, .7, .45).toColor(),
                            ], begin: Alignment.topRight, end: Alignment.bottomLeft),
                          ),
                          child: i == 3 ? const Text('+۱۲۰', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)) : null,
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
            const SectionTitle('گروه‌های مشترک', color: null),
            PCard(
              child: InfoRow(Icons.groups_outlined, 'تیم طراحی محصول', sub: 'سارا، علی، مریم و ۸ عضو دیگر',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen('design')))),
            ),
            const SizedBox(height: 12),
            PCard(
              child: DividerList([
                InfoRow(Icons.lock_clock_outlined, 'شروع گفتگوی محرمانه', sub: 'رمزنگاری دوسویه و حذف خودکار پیام‌ها',
                    onTap: () => toast(context, 'گفتگوی محرمانه فعال شد')),
                InfoRow(Icons.ios_share, 'اشتراک‌گذاری مخاطب', onTap: () {
                  Clipboard.setData(ClipboardData(text: '${x.name} @${x.user}'));
                  toast(context, 'اطلاعات مخاطب کپی شد');
                }),
                InfoRow(Icons.block, blocked ? 'رفع مسدودیت ${x.name}' : 'مسدود کردن ${x.name}', danger: true,
                    onTap: () async {
                      if (blocked) { app.toggleBlock(x.id); return; }
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('مسدود کردن'),
                          content: Text('${x.name} مسدود شود؟'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('مسدود شود', style: TextStyle(color: kRed))),
                          ],
                        ),
                      );
                      if (ok == true) app.toggleBlock(x.id);
                    }),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _pill(Pal p, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(99)),
        child: Directionality(
            textDirection: TextDirection.ltr, child: Text(t, style: TextStyle(fontSize: 13, color: p.chipText))),
      );
}

// ───────────────────────── تماس ─────────────────────────
void startCall(BuildContext context, String name, bool video) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: true,
    pageBuilder: (_, __, ___) => CallScreen(name: name, video: video),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

class CallScreen extends StatefulWidget {
  final String name;
  final bool video;
  const CallScreen({super.key, required this.name, required this.video});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int s = -1;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => s = 0);
      _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => s++));
    });
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final label = s < 0
        ? 'در حال برقراری ${widget.video ? 'تماس تصویری' : 'تماس صوتی'}…'
        : fa('${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}');
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: Column(children: [
                Avatar(widget.name, size: 128),
                const SizedBox(height: 18),
                Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Material(
                color: const Color(0xFFEF4444),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(width: 68, height: 68, child: Icon(Icons.call_end, color: Colors.white, size: 30)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
