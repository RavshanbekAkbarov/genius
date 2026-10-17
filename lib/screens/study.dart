import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/quotes.dart';
import '../services/ads.dart';
import '../services/net.dart';
import '../services/speech.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tools.dart';
import 'home.dart';
import 'offline.dart';
import 'profile.dart';

export '../state/app_state.dart' show CardItem;

/// Bitta mashq (yoki takror) jarayoni.
class Session {
  final List<CardItem> src;
  final List<CardItem> deck;
  final bool review; // 1·3·7·15·30 takrori: limitga kirmaydi
  final bool typing;
  final bool reverse;
  final bool daily; // "Bugungi mashq": takrorlardan keyin yangi so'zlarga o'tadi
  int pos = 0;
  int easy = 0;
  final Set<String> hard = {};
  final Map<int, bool> graded = {}; // karta o'rni -> Oson (true) / Qiyin (false)
  Session(List<CardItem> list,
      {required this.review, required this.typing, required this.reverse, this.daily = false})
      : src = List.of(list),
        deck = List.of(list);

  String get unitLabel {
    final us = src.map((c) => c.unit).toSet().toList()..sort();
    if (src.map((c) => c.book).toSet().length > 1) return 'Bugungi takrorlar';
    return us.length > 1 ? 'Unit ${us.first}–${us.last}' : 'Unit ${us.first}';
  }
}

/// Mashqni boshlash. Bepul limit tugagan bo'lsa (takrorlardan tashqari) limit oynasi chiqadi.
/// Internet yo'q bo'lsa kuniga [offlineSessions] ta mashq ruxsat, keyin "Internetni yoqing" oynasi.
Future<void> startSession(BuildContext context, List<CardItem> list,
    {required bool review, bool typing = false, bool? reverse, bool replace = false, bool daily = false}) async {
  final s = AppScope.read(context);
  if (list.isEmpty) return;
  if (!review && s.sessionsLeft <= 0) {
    showLimitSheet(context);
    return;
  }
  if (!s.isPremium) {
    var online = Net.online.value || await Net.check();
    if (!context.mounted) return;
    if (!online) {
      if (s.offlineLeft <= 0) {
        online = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const OfflineScreen())) ?? false;
        if (!online || !context.mounted) return;
      } else {
        s.useOffline();
        toast(context, "Internet yo'q: bugun yana ${s.offlineLeft} ta mashq qilish mumkin");
      }
    }
  }
  if (!review) s.useSession();
  s.logSession();
  s.pickBook(list.first.book);
  Ads.preload();
  final session =
      Session(list, review: review, typing: review ? false : typing, reverse: reverse ?? s.reverse, daily: daily);
  final route = MaterialPageRoute(builder: (_) => StudyScreen(session: session));
  replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

/// "Bugungi mashq": avval hamma takrorlar, keyin yangi so'zlar.
void startDaily(BuildContext context) {
  final s = AppScope.read(context);
  final reviews = s.allReviewCards();
  if (reviews.isNotEmpty) {
    startSession(context, reviews, review: true, daily: true);
    return;
  }
  final fresh = s.nextNewCards();
  if (fresh.isEmpty) {
    toast(context, "Bu kitobdagi hamma so'zlar yodlangan. Boshqa kitobni tanlang");
    return;
  }
  startSession(context, fresh, review: false);
}

void showLimitSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: C.sf,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Pill('$freeSessions/$freeSessions', bg: C.bad, fg: Color(0xFF2A0606)),
          const SizedBox(width: 10),
          Expanded(child: Text('Bugungi bepul mashqlar tugadi', style: display(17))),
        ]),
        const SizedBox(height: 10),
        const Text(
            "Bepulda kuniga $freeSessions ta mashq qilish mumkin. Ertaga soat 00:00 da yana $freeSessions ta ochiladi. 1·3·7·15·30 kunlik takrorlar doim bepul.",
            style: TextStyle(color: C.mut, fontSize: 13)),
        const SizedBox(height: 14),
        Btn("Premium · ${money(premiumPrice)} so'm/oy",
            icon: const Icon(Icons.workspace_premium_rounded, color: C.onAc, size: 20), onTap: () {
          Navigator.pop(ctx);
          push(context, const PremiumScreen());
        }),
        const SizedBox(height: 4),
        Btn('Ertaga davom etaman', kind: BtnKind.text, onTap: () => Navigator.pop(ctx)),
      ]),
    ),
  );
}

class StudyScreen extends StatefulWidget {
  final Session session;
  const StudyScreen({super.key, required this.session});
  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  Session get ss => widget.session;
  final pages = PageController(viewportFraction: .8);
  final answer = TextEditingController();
  final answerFocus = FocusNode();
  ({String value, bool ok})? answered;
  bool finishing = false;

  CardItem get card => ss.deck[min(ss.pos, ss.deck.length - 1)];

  @override
  void dispose() {
    pages.dispose();
    answer.dispose();
    answerFocus.dispose();
    Speech.stop();
    super.dispose();
  }

  void markHard(CardItem c) {
    AppScope.read(context).markHard(c, review: ss.review);
    ss.hard.add(c.key);
    // So'z 3 ta kartadan keyin yana chiqadi.
    final at = min(ss.deck.length, ss.pos + 4);
    ss.deck.insert(at, c);
    final moved = {for (final e in ss.graded.entries) (e.key >= at ? e.key + 1 : e.key): e.value};
    ss.graded
      ..clear()
      ..addAll(moved);
  }

  void markEasy(CardItem c) {
    AppScope.read(context).markEasy(c, review: ss.review);
    ss.easy++;
  }

  /// Kartalar: baholash va keyingi baholanmagan kartaga o'tish.
  void grade(bool easy) {
    if (ss.graded.containsKey(ss.pos)) {
      _goNext();
      return;
    }
    ss.graded[ss.pos] = easy;
    easy ? markEasy(card) : markHard(card);
    _goNext();
  }

  void _goNext() {
    if (ss.graded.length >= ss.deck.length) {
      finish();
      return;
    }
    var next = ss.pos + 1;
    while (next < ss.deck.length && ss.graded.containsKey(next)) {
      next++;
    }
    if (next >= ss.deck.length) {
      next = List.generate(ss.deck.length, (i) => i).firstWhere((i) => !ss.graded.containsKey(i));
    }
    setState(() {});
    pages.animateToPage(next, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  /// Yozish rejimi: keyingi so'z.
  void next() {
    ss.pos++;
    answered = null;
    answer.clear();
    if (ss.pos >= ss.deck.length) {
      finish();
      return;
    }
    setState(() {});
    answerFocus.requestFocus();
  }

  Future<void> finish() async {
    if (finishing) return;
    finishing = true;
    final s = AppScope.read(context);
    if (!s.isPremium) await Ads.showInterstitial(context, label: 'Mashq tugadi');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DoneScreen(session: ss)));
  }

  void check() {
    final v = answer.text;
    if (v.trim().isEmpty) {
      answerFocus.requestFocus();
      return;
    }
    final c = card;
    final targets = ss.reverse ? [c.word.en] : c.word.uz.split(',').map((x) => x.trim()).toList();
    final ok = targets.any((t) => normalize(t) == normalize(v));
    if (ok) {
      markEasy(c);
      if (ss.reverse) Speech.speak(c.word.en);
    } else {
      markHard(c);
    }
    setState(() => answered = (value: v, ok: ok));
  }

  void skip() {
    markHard(card);
    setState(() => answered = (value: '', ok: false));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(card.book);
    final mode = ss.review ? 'Takrorlash' : ss.typing ? 'Yozish' : 'Kartalar';
    final done = ss.typing ? ss.pos : ss.graded.length;
    return Scaffold(
      appBar: TopBar(
        title: ss.unitLabel,
        book: b,
        subtitle: '$mode · ${min(ss.pos + 1, ss.deck.length)}/${ss.deck.length}',
        actions: const [FontButtons(), VoiceButton()],
      ),
      bottomNavigationBar: s.isPremium ? null : const SafeArea(top: false, child: AdBanner()),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: done / ss.deck.length, minHeight: 7, color: C.gold, backgroundColor: C.sf2),
          ),
        ),
        Expanded(child: ss.typing ? _typing(s) : _cards(s)),
      ]),
    );
  }

  Widget _cards(AppState s) {
    final g = ss.graded[ss.pos];
    return Column(children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Kartani bosing: aylanadi · suring: keyingi va oldingi karta',
            textAlign: TextAlign.center, style: TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: PageView.builder(
              controller: pages,
              itemCount: ss.deck.length,
              onPageChanged: (i) => setState(() => ss.pos = i),
              itemBuilder: (_, i) => AnimatedScale(
                scale: i == ss.pos ? 1 : .9,
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: i == ss.pos ? 1 : .45,
                  duration: const Duration(milliseconds: 220),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FlipCard(
                      key: ValueKey('card-$i-${ss.deck[i].key}'),
                      item: ss.deck[i],
                      reverse: ss.reverse,
                      scale: s.fontScale,
                      active: i == ss.pos,
                      grade: ss.graded[i],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(children: [
          Expanded(
              child: _gradeBtn('Qiyin', ss.review ? 'ertaga yana' : "yana ko'rsatiladi", C.bad, g == false,
                  () => grade(false))),
          const SizedBox(width: 12),
          Expanded(
              child:
                  _gradeBtn('Oson', ss.review ? 'keyingi bosqich' : 'yodladim', C.good, g == true, () => grade(true))),
        ]),
      ),
    ]);
  }

  Widget _gradeBtn(String t, String sub, Color c, bool chosen, VoidCallback onTap) => Material(
        color: chosen ? c.withValues(alpha: .22) : C.sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c, width: 2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 62,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(sub, style: const TextStyle(color: C.mut, fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _typing(AppState s) {
    final w = card.word;
    final promptEn = !ss.reverse;
    final a = answered;
    final f = s.fontScale;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
      GestureDetector(
        onTap: promptEn ? () => Speech.speak(w.en) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            Text(promptEn ? "O'zbekchasini yozing" : 'Inglizchasini yozing',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: .85))),
            const SizedBox(height: 10),
            Text(promptEn ? w.en : w.uz, textAlign: TextAlign.center, style: display(30 * f, color: Colors.white)),
            if (promptEn) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.volume_up_rounded, size: 18, color: Colors.white),
                  if (w.ipa.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(w.ipa, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ]),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: answer,
        focusNode: answerFocus,
        autofocus: true,
        readOnly: a != null,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: (_) => a == null ? check() : next(),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18 * f),
        decoration: InputDecoration(
          hintText: 'Javobni yozing',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: a == null ? C.ln : (a.ok ? C.good : C.bad), width: 2),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (a != null) ...[
        Text(a.ok ? "✓ To'g'ri!" : "✕ To'g'ri javob: ${promptEn ? w.uz : w.en}",
            style: TextStyle(color: a.ok ? C.good : C.bad, fontWeight: FontWeight.w800, fontSize: 16 * f)),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            avatar: const Icon(Icons.volume_up_rounded, size: 18),
            label: Text('${w.en} ${w.ipa}'),
            onPressed: () => Speech.speak(w.en),
          ),
        ),
        const SizedBox(height: 10),
        Btn('Keyingisi', onTap: next),
      ] else
        Row(children: [
          Expanded(child: Btn('Tekshirish', onTap: check)),
          const SizedBox(width: 10),
          Expanded(child: Btn('Bilmayman', kind: BtnKind.ghost, onTap: skip)),
        ]),
    ]);
  }
}

/// Ikki tomonlama karta: bosganda 3D aylanadi. Ikkala tomon bir xil ko'rinishda.
class FlipCard extends StatefulWidget {
  final CardItem item;
  final bool reverse;
  final double scale;
  final bool active;
  final bool? grade;
  const FlipCard(
      {super.key, required this.item, required this.reverse, required this.scale, required this.active, this.grade});
  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  bool back = false;

  @override
  void dispose() {
    anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    // Boshqa kartaga o'tilganda old tomoniga qaytadi.
    if (old.active && !widget.active && back) {
      back = false;
      anim.value = 0;
    }
  }

  void flip() {
    if (!widget.active) return;
    back = !back;
    back ? anim.forward() : anim.reverse();
    final enNow = widget.reverse ? back : !back;
    if (enNow) Speech.speak(widget.item.word.en);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Karta: aylantirish',
      child: GestureDetector(
        onTap: flip,
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, _) {
            final a = Curves.easeInOut.transform(anim.value) * pi;
            final showBack = a > pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0012)
                ..rotateY(a),
              child: showBack
                  ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: _side(true))
                  : _side(false),
            );
          },
        ),
      ),
    );
  }

  Widget _side(bool isBack) {
    final w = widget.item.word;
    final en = widget.reverse ? isBack : !isBack;
    final f = widget.scale;
    final g = widget.grade;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: C.grad,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: g == null ? Colors.white12 : (g ? C.good : C.bad), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 14),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text(en ? 'INGLIZCHA' : "O'ZBEKCHA",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                    color: Colors.white.withValues(alpha: .75))),
          ),
          if (en)
            IconButton(
              tooltip: 'Talaffuz',
              onPressed: () => Speech.speak(w.en),
              icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
            )
          else
            const SizedBox(height: 48),
        ]),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(en ? w.en : w.uz, textAlign: TextAlign.center, style: display(30 * f, color: Colors.white)),
                if (en && w.ipa.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(w.ipa, style: TextStyle(fontSize: 15 * f, color: Colors.white70)),
                ],
                if (isBack && w.ex.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(w.ex,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14 * f, color: Colors.white.withValues(alpha: .8), fontStyle: FontStyle.italic)),
                ],
              ]),
            ),
          ),
        ),
        Icon(Icons.threesixty_rounded, color: Colors.white.withValues(alpha: .5), size: 22),
      ]),
    );
  }
}

class DoneScreen extends StatelessWidget {
  final Session session;
  const DoneScreen({super.key, required this.session});
  @override
  Widget build(BuildContext context) {
    final ss = session;
    final s = AppScope.of(context);
    final hardN = ss.hard.length;
    final xp = ss.review ? ss.easy * 5 : ss.easy * 10;
    final fresh = ss.daily ? s.nextNewCards() : const <CardItem>[];
    final q = quoteOfDay(s.today, slot: 1);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 32, 16, 24), children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: C.grad),
              child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          Text('${ss.unitLabel} tugadi!', textAlign: TextAlign.center, style: display(22)),
          const SizedBox(height: 8),
          Text(
            "${ss.src.length} ta so'z: ${ss.easy} tasi \"Oson\", $hardN tasi \"Qiyin\". Osonlari 1, 3, 7, 15 va 30 kundan keyin takrorlashga qaytadi.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.mut),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _stat('+$xp', 'XP')),
            const SizedBox(width: 10),
            Expanded(child: _stat('$hardN', "qiyin so'z")),
          ]),
          const SizedBox(height: 14),
          QuoteCard(quote: q),
          const SizedBox(height: 14),
          if (fresh.isNotEmpty) ...[
            Btn("Yangi so'zlarga o'tish · Unit ${fresh.first.unit} (${fresh.length})",
                onTap: () => startSession(context, fresh, review: false, replace: true)),
            const SizedBox(height: 10),
          ],
          Btn('Davom etish',
              kind: fresh.isNotEmpty ? BtnKind.ghost : BtnKind.primary, onTap: () => Navigator.of(context).pop()),
          const SizedBox(height: 10),
          if (!ss.review) ...[
            Btn('Qaytarish (hammasini qayta)',
                kind: BtnKind.ghost,
                onTap: () =>
                    startSession(context, ss.src, review: false, typing: ss.typing, reverse: ss.reverse, replace: true)),
            const SizedBox(height: 10),
          ],
          Btn("Qiyinlarini qayta ko'rish${hardN > 0 ? ' ($hardN)' : ''}",
              kind: BtnKind.ghost,
              onTap: hardN == 0
                  ? null
                  : () => startSession(context, ss.src.where((c) => ss.hard.contains(c.key)).toList(),
                      review: false, typing: ss.typing, reverse: ss.reverse, replace: true)),
        ]),
      ),
    );
  }

  Widget _stat(String v, String l) => AppCard(
        child: Column(children: [
          Text(v, style: display(22)),
          Text(l, style: const TextStyle(color: C.mut, fontSize: 12)),
        ]),
      );
}

/// Motivatsion gap: inglizcha asl matn va o'zbekcha tarjimasi.
class QuoteCard extends StatelessWidget {
  final Quote quote;
  const QuoteCard({super.key, required this.quote});
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.format_quote_rounded, color: C.gold),
            SizedBox(width: 6),
            Eyebrow('Kunning gapi'),
          ]),
          const SizedBox(height: 8),
          Text(quote.en, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.35)),
          const SizedBox(height: 6),
          Text(quote.uz, style: const TextStyle(color: C.mut, fontSize: 13, height: 1.35)),
          const SizedBox(height: 8),
          Text('— ${quote.author}', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      );
}
