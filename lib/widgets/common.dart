import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../theme.dart';

void toast(BuildContext context, String msg) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg, textAlign: TextAlign.center),
    duration: const Duration(milliseconds: 2400),
    margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ));
}

/// Kitob belgisi: rangli kitobcha va uning raqami.
class BookBadge extends StatelessWidget {
  final Book book;
  final double size;
  const BookBadge(this.book, {super.key, this.size = 30});
  @override
  Widget build(BuildContext context) {
    final fs = size * (book.badge.length > 1 ? .36 : .5);
    return Container(
      width: size,
      height: size * 1.28,
      decoration: BoxDecoration(
        gradient: book.gradient,
        borderRadius: BorderRadius.circular(size * .22),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Stack(children: [
        Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: size * .14,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(size * .22))))),
        Center(child: Text(book.badge, style: display(fs, color: Colors.white))),
      ]),
    );
  }
}

/// Javondagi kitob muqovasi.
class BookCover extends StatelessWidget {
  final String badge, title;
  final Gradient gradient;
  final String? corner;
  final double? progress;
  final VoidCallback? onTap;
  const BookCover(
      {super.key, required this.badge, required this.title, required this.gradient, this.corner, this.progress, this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: GestureDetector(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 132,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(R.md),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Stack(children: [
              // Kitob umurtqasi va yaltiroq.
              Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 7,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .22),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(R.md))))),
              Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .10)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(badge, style: display(32, color: Colors.white)),
                      Text(title,
                          maxLines: 2,
                          style: const TextStyle(
                              fontSize: 11, height: 1.2, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
              ),
              if (corner != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                    child: Text(corner!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
            ]),
          ),
          if (progress != null) ...[
            const SizedBox(height: 9),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 5, color: C.good, backgroundColor: C.sf2),
                ),
              ),
              const SizedBox(width: 6),
              Text('${(progress! * 100).round()}%',
                  style: TextStyle(fontSize: 11, color: C.mut, fontWeight: FontWeight.w700)),
            ]),
          ],
        ]),
      ),
    );
  }
}

/// Halqa ko'rinishidagi progress (0..1). Ichiga istalgan narsa qo'yiladi.
class Ring extends StatelessWidget {
  final double value;
  final double size, stroke;
  final Color? color, track;
  final Widget? child;
  const Ring(this.value, {super.key, this.size = 58, this.stroke = 6, this.color, this.track, this.child});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0, 1).toDouble(), stroke, color ?? C.ac, track ?? C.sf2),
          child: Center(child: child),
        ),
      );
}

/// Kitob foizi halqasi (sarlavhalarda).
class PctRing extends StatelessWidget {
  final int pct;
  final double size;
  const PctRing(this.pct, {super.key, this.size = 58});
  @override
  Widget build(BuildContext context) => Ring(pct / 100,
      size: size,
      color: C.good,
      child: Text('$pct%', style: display(size * .24, color: C.fg)));
}

class _RingPainter extends CustomPainter {
  final double v, stroke;
  final Color color, track;
  _RingPainter(this.v, this.stroke, this.color, this.track);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - stroke / 2;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (v <= 0) return;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2,
        2 * pi * max(v, .02),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track;
}

/// Rangli fonli ikonka (ro'yxat va plitkalarda).
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  const IconBox(this.icon, {super.key, this.color, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: (color ?? C.ac).withValues(alpha: .16), borderRadius: BorderRadius.circular(size * .32)),
        child: Icon(icon, color: color ?? C.ac, size: size * .55),
      );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? border;
  final VoidCallback? onTap;
  const AppCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.border, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: color ?? C.sf,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.lg), side: BorderSide(color: border ?? C.ln)),
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

enum BtnKind { primary, ghost, telegram, text, gold }

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final Widget? icon;
  const Btn(this.label, {super.key, this.onTap, this.kind = BtnKind.primary, this.icon});
  @override
  Widget build(BuildContext context) {
    final bg = switch (kind) {
      BtnKind.primary => C.ac,
      BtnKind.ghost => C.sf2,
      BtnKind.telegram => C.tg,
      BtnKind.gold => C.gold,
      BtnKind.text => Colors.transparent,
    };
    final fg = switch (kind) {
      BtnKind.primary || BtnKind.telegram => Colors.white,
      BtnKind.gold => C.onGold,
      BtnKind.text => C.ac,
      _ => C.fg,
    };
    return Opacity(
      opacity: onTap == null ? .45 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(R.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                IconTheme(data: IconThemeData(color: fg, size: 20), child: icon!),
                const SizedBox(width: 8)
              ],
              Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15))),
            ]),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color? bg, fg;
  const Pill(this.text, {super.key, this.bg, this.fg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg ?? C.sf2, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: fg ?? C.fg, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? note;
  const SectionTitle(this.title, {super.key, this.action, this.onAction, this.note});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: display(18))),
        if (note != null) Text(note!, style: TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w600)),
        if (action != null)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(action!, style: TextStyle(color: C.ac, fontWeight: FontWeight.w800, fontSize: 13)),
                Icon(Icons.chevron_right_rounded, color: C.ac, size: 18),
              ]),
            ),
          ),
      ]);
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: C.mut));
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: C.sf,
          borderRadius: BorderRadius.circular(R.lg),
          border: Border.all(color: C.ln),
        ),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: C.mut, height: 1.45)),
      );
}

/// Ichki sahifalar uchun yuqori qator: orqaga, kitob belgisi, sarlavha.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Book? book;
  final VoidCallback? onBack;
  final List<Widget> actions;
  const TopBar({super.key, required this.title, this.subtitle, this.book, this.onBack, this.actions = const []});
  @override
  Size get preferredSize => const Size.fromHeight(68);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(children: [
          Material(
            color: C.sf2,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                  width: 42, height: 42, child: Icon(Icons.arrow_back_rounded, size: 22, semanticLabel: 'Orqaga')),
            ),
          ),
          const SizedBox(width: 12),
          if (book != null) ...[BookBadge(book!, size: 26), const SizedBox(width: 10)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: display(18), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null)
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          for (final a in actions) ...[const SizedBox(width: 6), a],
        ]),
      ),
    );
  }
}

/// Progress bilan to'ladigan ro'yxat qatori (kitob, unit).
class FillRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String trailing;
  final double fill;
  final bool done;
  final VoidCallback? onTap;
  const FillRow(
      {super.key,
      this.leading,
      required this.title,
      this.subtitle,
      required this.trailing,
      this.fill = 0,
      this.done = false,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.sf,
      borderRadius: BorderRadius.circular(R.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: done ? C.good.withValues(alpha: .4) : C.ln),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill.clamp(0, 1),
                child: Container(color: C.good.withValues(alpha: .12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Text(trailing,
                    style: TextStyle(color: done ? C.good : C.mut, fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final VoidCallback onTap;
  const SwitchRow({super.key, required this.title, this.subtitle, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (subtitle != null) Text(subtitle!, style: TextStyle(color: C.mut, fontSize: 12)),
              ]),
            ),
            Switch(value: value, onChanged: (_) => onTap()),
          ]),
        ),
      );
}

/// Kichik kvadrat tugma (A-, A+, 🔊).
class SquareBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? color;
  const SquareBtn({super.key, required this.child, required this.onTap, required this.tooltip, this.color});
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: color ?? C.sf2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 42, height: 42, child: Center(child: child)),
          ),
        ),
      );
}

/// Genius Premium reklamasi (Premium bo'lmaganlarga).
class PremiumPromo extends StatelessWidget {
  final VoidCallback onTap;
  const PremiumPromo({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(gradient: C.premiumGrad),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFF3A2208)),
                  SizedBox(width: 6),
                  Text('GENIUS PREMIUM',
                      style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w900, color: Color(0xFF3A2208))),
                ]),
                const SizedBox(height: 6),
                Text('Reklamasiz va cheksiz mashq', style: display(17, color: const Color(0xFF241200))),
                const SizedBox(height: 4),
                const Text(
                    "Kuniga $freeSessions ta emas, xohlagancha mashq. Reklamalar yo'q, internetsiz ham ishlaydi, olovni saqlash bepul.",
                    style: TextStyle(color: Color(0xFF3A2208), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF241200), borderRadius: BorderRadius.circular(14)),
                  child: Text("Premium · ${money(premiumPrice)} so'm/oy",
                      style: TextStyle(color: C.gold, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ),
      );
}
