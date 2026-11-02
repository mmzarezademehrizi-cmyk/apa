import 'package:flutter/material.dart';

const kPri = Color(0xFF2563EB);
const kPri2 = Color(0xFF1D4ED8);
const kOk = Color(0xFF10B981);
const kRed = Color(0xFFDC2626);

class Pal {
  final Color bg, card, line, ink, mut, chip, chipText, field;
  const Pal(this.bg, this.card, this.line, this.ink, this.mut, this.chip, this.chipText, this.field);
  static const light = Pal(Color(0xFFF8FAFC), Colors.white, Color(0xFFE2E8F0), Color(0xFF0F172A),
      Color(0xFF64748B), Color(0xFFE5EEFF), Color(0xFF1D4ED8), Color(0xFFF1F5F9));
  static const dark = Pal(Color(0xFF0B1220), Color(0xFF131C2E), Color(0xFF243049), Color(0xFFE2E8F0),
      Color(0xFF94A3B8), Color(0xFF1B2A4A), Color(0xFF93B4FF), Color(0xFF1A2438));
  static Pal of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

String initials(String name) {
  final re = RegExp(r'\p{L}', unicode: true);
  String first(String w) => re.firstMatch(w)?[0] ?? '';
  final parts = name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '؟';
  final s = parts.length > 1 ? first(parts[0]) + first(parts[1]) : first(parts[0]);
  return s.isEmpty ? '؟' : s;
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool online;
  const Avatar(this.name, {super.key, this.size = 48, this.online = false});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final h = name.runes.fold<int>(0, (a, r) => (a * 31 + r) % 360).toDouble();
    final c1 = HSLColor.fromAHSL(1, h, .70, .55).toColor();
    final c2 = HSLColor.fromAHSL(1, (h + 40) % 360, .70, .40).toColor();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topRight, end: Alignment.bottomLeft),
            border: Border.all(color: p.card, width: 2),
          ),
          child: Text(initials(name),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * .36)),
        ),
        if (online)
          PositionedDirectional(
            bottom: 0,
            start: 0,
            child: Container(
              width: size * .26,
              height: size * .26,
              decoration: BoxDecoration(
                  color: kOk, shape: BoxShape.circle, border: Border.all(color: p.card, width: 2)),
            ),
          ),
      ]),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 16});
  @override
  Widget build(BuildContext context) => Icon(Icons.verified, color: kPri, size: size);
}

class PCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const PCard({super.key, required this.child, this.padding, this.margin});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionTitle(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
        child: Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? kPri)),
      );
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? tag;
  const InfoRow(this.icon, this.title,
      {super.key, this.sub, this.trailing, this.onTap, this.danger = false, this.tag});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: danger ? const Color(0x1FDC2626) : p.chip, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: danger ? kRed : p.chipText, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                    child: Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.5, color: danger ? kRed : p.ink))),
                if (tag != null) ...[const SizedBox(width: 8), tag!],
              ]),
              if (sub != null && sub!.isNotEmpty)
                Text(sub!, style: TextStyle(fontSize: 12.5, color: p.mut, height: 1.5)),
            ]),
          ),
          trailing ?? Icon(Icons.chevron_left, color: p.mut),
        ]),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  const Tag(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, color: p.chipText, fontWeight: FontWeight.w500)),
    );
  }
}

class DividerList extends StatelessWidget {
  final List<Widget> children;
  const DividerList(this.children, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(Divider(height: 1, color: p.line));
      out.add(children[i]);
    }
    return Column(children: out);
  }
}

void toast(BuildContext c, String t) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(t, textAlign: TextAlign.center), duration: const Duration(milliseconds: 1600)));
}
