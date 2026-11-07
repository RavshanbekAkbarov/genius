import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/stories.dart';
import '../data/words.dart';
import '../data/uzform.dart';
import '../services/ads.dart';
import '../services/speech.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tools.dart';
import 'home.dart';
import 'study.dart';

final _wordRe = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?");

/// Unit ekranidagi hikoya kartasi: o'qish yoki tinglash.
class StoryCard extends StatelessWidget {
  final String bookId;
  final int unit;
  const StoryCard({super.key, required this.bookId, required this.unit});
  @override
  Widget build(BuildContext context) {
    final st = StoryBank.of(bookId, unit);
    if (st == null) return const SizedBox.shrink();
    final s = AppScope.of(context);
    final read = s.storiesRead.contains(st.id);
    void open(bool listen) => push(context, StoryScreen(bookId: bookId, unit: unit, autoplay: listen));
    return Container(
      decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(R.xl)),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(read ? "O'QILGAN ✓ · ${st.minutes} DAQIQALIK O'QISH" : "HIKOYA · ${st.minutes} DAQIQALIK O'QISH",
            style: TextStyle(
                color: Colors.white.withValues(alpha: .75),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(st.title, style: display(21, color: Colors.white)),
        const SizedBox(height: 6),
        Text("Unit so'zlari hikoyada uchraydi. Istalgan so'zni bossangiz, tarjimasi chiqadi.",
            style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            flex: 3,
            child: _HeroBtn(
                icon: Icons.menu_book_rounded,
                label: read ? 'Qayta o\'qish' : "O'qish",
                bg: Colors.white,
                fg: const Color(0xFF2B2A9E),
                onTap: () => open(false)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _HeroBtn(
                icon: Icons.play_arrow_rounded,
                label: 'Tinglash',
                bg: Colors.white.withValues(alpha: .18),
                fg: Colors.white,
                onTap: () => open(true)),
          ),
        ]),
      ]),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _HeroBtn({required this.icon, required this.label, required this.bg, required this.fg, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        borderRadius: BorderRadius.circular(R.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14.5))),
            ]),
          ),
        ),
      );
}

/// Hikoyani o'qish: istalgan so'z bosiladi, unit so'zlari ajralib turadi, ovoz bilan tinglash mumkin.
class StoryScreen extends StatefulWidget {
  final String bookId;
  final int unit;
  final bool autoplay;
  const StoryScreen({super.key, required this.bookId, required this.unit, this.autoplay = false});
  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  late final Story st = StoryBank.of(widget.bookId, widget.unit)!;
  final scroll = ScrollController();
  final _recognizers = <TapGestureRecognizer>[];
  final tapped = <String>{};
  final started = DateTime.now();
  int saved = 0;
  double progress = 0;
  String? selected; // "paragraf:boshlanish"
  int playing = -1;
  bool _stop = false;
  Set<String>? _unitWords;

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      final m = scroll.position.maxScrollExtent;
      final p = m <= 0 ? 1.0 : (scroll.offset / m).clamp(0.0, 1.0);
      if ((p - progress).abs() > .01) setState(() => progress = p);
    });
    if (widget.autoplay) WidgetsBinding.instance.addPostFrameCallback((_) => play());
  }

  @override
  void dispose() {
    _stop = true;
    Speech.stop();
    for (final r in _recognizers) {
      r.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  Set<String> unitWords(AppState s) => _unitWords ??=
      s.words(widget.bookId, widget.unit).map((w) => w.en.toLowerCase()).toSet();

  Future<void> play() async {
    if (playing >= 0) {
      _stop = true;
      await Speech.stop();
      if (mounted) setState(() => playing = -1);
      return;
    }
    _stop = false;
    for (var i = 0; i < st.paras.length; i++) {
      if (_stop || !mounted) break;
      setState(() => playing = i);
      await Speech.speak(st.paras[i], speed: .9);
    }
    if (mounted) setState(() => playing = -1);
  }

  void openWord(String token, int para, int start) {
    final e = StoryBank.lookup(token);
    setState(() {
      selected = '$para:$start';
      tapped.add(e?.lemma ?? token.toLowerCase());
    });
    final sentence = _sentenceAt(st.paras[para], start);
    final s = AppScope.read(context);
    final isUnit = unitWords(s).contains(e?.lemma) || unitWords(s).contains(token.toLowerCase());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordSheet(
        token: token,
        entry: e,
        sentence: sentence,
        prev: RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?")
            .allMatches(st.paras[para].substring(0, start))
            .map((m) => StoryBank.norm(m.group(0)!))
            .toList()
            .reversed
            .take(3)
            .toList(),
        unitLabel: isUnit ? 'Unit ${widget.unit} so\'zi' : null,
        onSaved: () => saved++,
      ),
    ).whenComplete(() {
      if (mounted) setState(() => selected = null);
    });
  }

  static String _sentenceAt(String p, int at) {
    final ends = RegExp(r'[.!?]["”’]?\s+');
    var a = 0;
    for (final m in ends.allMatches(p)) {
      if (m.end > at) return p.substring(a, m.end).trim();
      a = m.end;
    }
    return p.substring(a).trim();
  }

  TextSpan _para(AppState s, int pi, TextStyle base) {
    final text = st.paras[pi];
    final spans = <InlineSpan>[];
    var last = 0;
    final uw = unitWords(s);
    for (final m in _wordRe.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final tok = m.group(0)!;
      final lem = StoryBank.lemmaOf(tok);
      final isUnit = uw.contains(lem) || uw.contains(StoryBank.norm(tok));
      final on = selected == '$pi:${m.start}';
      final r = TapGestureRecognizer()..onTap = () => openWord(tok, pi, m.start);
      _recognizers.add(r);
      spans.add(TextSpan(
        text: tok,
        recognizer: r,
        style: on
            ? TextStyle(color: Colors.white, background: Paint()..color = C.ac, fontWeight: FontWeight.w700)
            : isUnit
                ? TextStyle(
                    color: C.light ? C.ac : const Color(0xFFA9BEFF),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: C.ac,
                    decorationThickness: 2)
                : null,
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: base, children: spans);
  }

  void finish() {
    final s = AppScope.read(context);
    s.markStoryRead(st.id);
    Speech.stop();
    _stop = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => StoryDoneScreen(
              bookId: widget.bookId,
              unit: widget.unit,
              time: DateTime.now().difference(started),
              tapped: tapped.length,
              saved: saved,
            )));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(widget.bookId);
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final base = TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontSize: 17 * s.fontScale,
        height: 1.7,
        fontWeight: FontWeight.w500,
        color: C.fg);
    final uw = unitWords(s);
    return Scaffold(
      appBar: TopBar(title: 'Hikoya', subtitle: '${b.title} · Unit ${widget.unit}', actions: const [FontButtons()]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: _PlayerBar(playing: playing >= 0, onTap: play),
          ),
          if (!s.isPremium) const AdBanner(),
        ]),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 4, color: C.ac, backgroundColor: C.sf2),
          ),
        ),
        Expanded(
          child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
            Text(st.title, style: display(24)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              Pill('⏱ ${st.minutes} daqiqa', fg: C.mut),
              if (uw.isNotEmpty) Pill("${uw.length} ta unit so'zi", bg: C.tint(C.ac), fg: C.light ? C.ac : const Color(0xFFA9BEFF)),
            ]),
            const SizedBox(height: 10),
            Text("Istalgan so'zni bosing: tarjimasi va sinonimlari chiqadi.",
                style: TextStyle(color: C.mut, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            for (var i = 0; i < st.paras.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: playing == i ? const EdgeInsets.fromLTRB(10, 6, 10, 6) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: playing == i ? C.tint(C.ac, .12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                child: Text.rich(_para(s, i, base)),
              ),
            const SizedBox(height: 8),
            Btn(st.qs.isEmpty ? 'Hikoyani tugatdim' : 'Tugatdim · ${st.qs.length} ta savol',
                icon: const Icon(Icons.check_rounded), onTap: finish),
          ]),
        ),
      ]),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  const _PlayerBar({required this.playing, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: C.sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg), side: BorderSide(color: C.ln)),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: C.ac, shape: BoxShape.circle),
                child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(playing ? "O'qilmoqda…" : 'Tinglash', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('Matn ovoz bilan, paragraf-paragraf yoritiladi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

/// So'z bosilganda pastdan chiqadigan oyna: tarjima, sinonimlar, talaffuz, hikoyadagi gap.
class WordSheet extends StatefulWidget {
  final String token;
  final DictEntry? entry;
  final String sentence;
  final String? unitLabel;
  final VoidCallback? onSaved;

  /// So'zdan oldingi so'zlar (yaqinidan boshlab): shaklni aniqlash uchun.
  final List<String> prev;
  const WordSheet(
      {super.key,
      required this.token,
      required this.entry,
      required this.sentence,
      this.unitLabel,
      this.onSaved,
      this.prev = const []});
  @override
  State<WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends State<WordSheet> {
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = widget.entry;
    final word = e?.lemma ?? widget.token.toLowerCase();
    final form = StoryBank.norm(widget.token);
    final has = s.hasMyWord(word);
    final cf = e == null ? null : contextForm(widget.token, word, e.uz, widget.prev);
    final k = TextStyle(color: C.dim, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Katta harflarda: so'z matndagi shaklida; pastida asosiy (lug'at) shakli.
                Text(form, style: display(30)),
                Text(
                    [
                      if (form != word) 'asosiy shakli: $word',
                      if (e != null && e.ipa.isNotEmpty) e.ipa,
                    ].join(' · '),
                    style: TextStyle(color: C.mut, fontSize: 15, fontFamily: 'Ipa', fontFamilyFallback: const [fontFamily])),
              ]),
            ),
            Material(
              color: C.tint(C.ac),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Speech.speak(form),
                child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.volume_up_rounded, color: C.ac, semanticLabel: 'Talaffuz')),
              ),
            ),
          ]),
          if (widget.unitLabel != null) ...[
            const SizedBox(height: 10),
            Pill('★ ${widget.unitLabel}', bg: C.tint(C.ac), fg: C.light ? C.ac : const Color(0xFFA9BEFF)),
          ],
          const SizedBox(height: 16),
          Text('TARJIMA', style: k),
          const SizedBox(height: 6),
          if (cf != null) ...[
            Text(cf.uz, style: display(19, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${cf.note} · $word - ${e!.uz}',
                style: TextStyle(color: C.mut, fontSize: 13, fontWeight: FontWeight.w600)),
          ] else
            Text(e?.uz ?? "Bu so'z lug'atda yo'q", style: display(19, weight: FontWeight.w800)),
          if (e != null && e.syn.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('SINONIMLAR', style: k),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final w in e.syn)
                Material(
                  color: C.sf2,
                  borderRadius: BorderRadius.circular(R.sm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(R.sm),
                    onTap: () => Speech.speak(w),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: w, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        if (StoryBank.lookup(w) case final x? when x.lemma != word)
                          TextSpan(
                              text: '  ${x.uz.split(RegExp(r'[,;]')).first}',
                              style: TextStyle(color: C.mut, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ])),
                    ),
                  ),
                ),
            ]),
          ],
          const SizedBox(height: 16),
          Text('HIKOYADA', style: k),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: C.sf2,
              borderRadius: BorderRadius.circular(R.md),
              border: Border(left: BorderSide(color: C.ac, width: 3)),
            ),
            child: Text(widget.sentence, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
          const SizedBox(height: 16),
          Btn(has ? "Mening so'zlarimda bor ✓" : "★ Mening so'zlarimga qo'shish",
              kind: has ? BtnKind.ghost : BtnKind.primary,
              onTap: has || e == null
                  ? null
                  : () {
                      s.addMyWord(Word(word, e.uz, e.ipa, widget.sentence));
                      widget.onSaved?.call();
                      setState(() {});
                      toast(context, "\"$word\" Mening so'zlarimga qo'shildi");
                    }),
        ]),
      ),
    );
  }
}

/// Hikoya tugadi: natija, savollar va keyingi qadam.
class StoryDoneScreen extends StatefulWidget {
  final String bookId;
  final int unit;
  final Duration time;
  final int tapped, saved;
  const StoryDoneScreen(
      {super.key, required this.bookId, required this.unit, required this.time, required this.tapped, required this.saved});
  @override
  State<StoryDoneScreen> createState() => _StoryDoneScreenState();
}

class _StoryDoneScreenState extends State<StoryDoneScreen> {
  late final Story st = StoryBank.of(widget.bookId, widget.unit)!;
  final picked = <int, int>{};

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final m = widget.time.inMinutes, sec = widget.time.inSeconds % 60;
    final right = picked.entries.where((e) => st.qs[e.key].answer == e.value).length;
    final next = StoryBank.of(widget.bookId, widget.unit + 1);
    final w = s.words(widget.bookId, widget.unit);
    Widget stat(String v, String l) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration:
                BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(R.md)),
            child: Column(children: [
              Text(v, style: display(19, color: Colors.white)),
              Text(l,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .8), fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(R.xl)),
            child: Column(children: [
              const Text('📖', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 6),
              Text('Barakalla!', style: display(24, color: Colors.white)),
              const SizedBox(height: 4),
              Text('"${st.title}" hikoyasini ${m > 0 ? '$m daq ' : ''}$sec son.da o\'qidingiz',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: .85), fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(children: [
                stat('${widget.tapped}', "so'z bosildi"),
                const SizedBox(width: 8),
                stat('${widget.saved}', 'saqlandi'),
                const SizedBox(width: 8),
                stat(picked.length == st.qs.length && st.qs.isNotEmpty ? '$right/${st.qs.length}' : '–', "to'g'ri javob"),
              ]),
            ]),
          ),
          if (st.qs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Tushundingizmi?', style: display(19)),
            const SizedBox(height: 4),
            Text('Javobni bosing: to\'g\'risi yashil bo\'ladi.',
                style: TextStyle(color: C.mut, fontSize: 13, fontWeight: FontWeight.w600)),
            for (var qi = 0; qi < st.qs.length; qi++) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('${qi + 1}. ${st.qs[qi].q}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  for (var oi = 0; oi < st.qs[qi].options.length; oi++) _option(qi, oi),
                ]),
              ),
            ],
          ],
          const SizedBox(height: 18),
          if (w.isNotEmpty)
            Btn("Unit so'zlarini mashq qilish",
                icon: const Icon(Icons.style_rounded),
                onTap: () => startSession(
                    context,
                    [for (var i = 0; i < w.length; i++) CardItem(wkey(widget.bookId, widget.unit, i), widget.bookId, widget.unit, w[i])],
                    review: false,
                    replace: true)),
          const SizedBox(height: 10),
          if (next != null)
            Btn('Keyingi hikoya: Unit ${widget.unit + 1}',
                kind: BtnKind.ghost,
                icon: const Icon(Icons.arrow_forward_rounded),
                onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => StoryScreen(bookId: widget.bookId, unit: widget.unit + 1))))
          else
            Btn('Yopish', kind: BtnKind.ghost, onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }

  Widget _option(int qi, int oi) {
    final q = st.qs[qi];
    final p = picked[qi];
    final done = p != null;
    final isRight = oi == q.answer;
    final color = !done
        ? C.sf2
        : isRight
            ? C.tint(C.good, .22)
            : p == oi
                ? C.tint(C.bad, .22)
                : C.sf2;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(R.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.sm),
          onTap: done ? null : () => setState(() => picked[qi] = oi),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(children: [
              Text('${'abcd'[oi]})', style: TextStyle(color: C.mut, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Expanded(child: Text(q.options[oi], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              if (done && isRight) Icon(Icons.check_circle_rounded, color: C.good, size: 20),
              if (done && p == oi && !isRight) Icon(Icons.cancel_rounded, color: C.bad, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}
