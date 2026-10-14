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
      height: size * 1.3,
      decoration: BoxDecoration(
        gradient: book.gradient,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Stack(children: [
        Positioned(left: 0, top: 0, bottom: 0, width: 4, child: Container(color: Colors.black26)),
        Center(child: Text(book.badge, style: display(fs, color: Colors.white, weight: FontWeight.w700))),
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
      width: 92,
      child: GestureDetector(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 124,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Stack(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(badge, style: display(30, color: Colors.white, weight: FontWeight.w700)),
                Text(title.toUpperCase(),
                    style: const TextStyle(fontSize: 9, letterSpacing: .4, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
              if (corner != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(7)),
                    child: Text(corner!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
            ]),
          ),
          if (progress != null) ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress, minHeight: 5, color: C.good, backgroundColor: C.sf2),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Tepadagi katta foiz halqasi: yodlangan qismi to'qroq.
class PctRing extends StatelessWidget {
  final int pct;
  final double size;
  const PctRing(this.pct, {super.key, this.size = 58});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(pct / 100),
        child: Center(child: Text('$pct%', style: display(14, color: Colors.white, weight: FontWeight.w700))),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  _RingPainter(this.v);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 3.5;
    final bg = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final fg = Paint()
      ..color = const Color(0xFF081A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2552C4));
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * max(v, .01), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v;
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? border;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.border});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? C.sf,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border ?? C.ln),
        ),
        child: child,
      );
}

enum BtnKind { primary, ghost, telegram, text }

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
      BtnKind.text => Colors.transparent,
    };
    final fg = switch (kind) {
      BtnKind.primary => C.onAc,
      BtnKind.telegram => Colors.white,
      _ => C.fg,
    };
    return Opacity(
      opacity: onTap == null ? .45 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
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
  final Color bg, fg;
  const Pill(this.text, {super.key, this.bg = C.sf2, this.fg = C.fg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
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
        Expanded(child: Text(title, style: display(17))),
        if (note != null) Text(note!, style: const TextStyle(color: C.mut, fontSize: 12)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(color: C.ac, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
      ]);
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: C.mut));
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.sf,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.ln),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: C.mut)),
      );
}

/// Ichki sahifalar uchun yuqori qator: orqaga, kitob belgisi, sarlavha.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Book? book;
  final VoidCallback? onBack;
  const TopBar({super.key, required this.title, this.subtitle, this.book, this.onBack});
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
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                  width: 40, height: 40, child: Icon(Icons.chevron_left_rounded, size: 28, semanticLabel: 'Orqaga')),
            ),
          ),
          const SizedBox(width: 12),
          if (book != null) ...[BookBadge(book!, size: 26), const SizedBox(width: 10)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: display(18), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
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
      borderRadius: BorderRadius.circular(16),
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
                child: Container(color: C.good.withValues(alpha: .13)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle!, style: const TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w600)),
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
                if (subtitle != null) Text(subtitle!, style: const TextStyle(color: C.mut, fontSize: 12)),
              ]),
            ),
            Switch(value: value, onChanged: (_) => onTap()),
          ]),
        ),
      );
}
