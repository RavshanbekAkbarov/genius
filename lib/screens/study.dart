import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../services/ads.dart';
import '../services/speech.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'profile.dart';

export '../state/app_state.dart' show CardItem;

/// Bitta mashq (yoki takror) jarayoni.
class Session {
  final List<CardItem> src;
  final List<CardItem> deck;
  final bool review; // 1·3·7·15·30 takrori: limitga kirmaydi
  final bool typing;
  final bool reverse;
  int pos = 0;
  int easy = 0;
  final Set<String> hard = {};
  Session(List<CardItem> list, {required this.review, required this.typing, required this.reverse})
      : src = List.of(list),
        deck = List.of(list);

  String get unitLabel {
    final us = src.map((c) => c.unit).toSet().toList()..sort();
    return us.length > 1 ? 'Unit ${us.first}–${us.last}' : 'Unit ${us.first}';
  }
}

/// Mashqni boshlash. Bepul limit tugagan bo'lsa (takrorlardan tashqari) limit oynasi chiqadi.
void startSession(BuildContext context, List<CardItem> list,
    {required bool review, bool typing = false, bool reverse = false, bool replace = false}) {
  final s = AppScope.read(context);
  if (list.isEmpty) return;
  if (!review && s.sessionsLeft <= 0) {
    showLimitSheet(context);
    return;
  }
  if (!review) s.useSession();
  s.pickBook(list.first.book);
  final session = Session(list, review: review, typing: review ? false : typing, reverse: review ? false : reverse);
  final route = MaterialPageRoute(builder: (_) => StudyScreen(session: session));
  replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
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
        const SizedBox(height: 10),
        Btn("Do'st taklif qilish: 1 hafta bepul", kind: BtnKind.ghost, onTap: () {
          Navigator.pop(ctx);
          push(context, const InviteScreen());
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
  bool flipped = false;
  bool pulse = false;
  final answer = TextEditingController();
  final answerFocus = FocusNode();
  ({String value, bool ok})? answered;

  CardItem get card => ss.deck[min(ss.pos, ss.deck.length - 1)];

  /// Hozir inglizcha tomon ko'rinyaptimi.
  bool get enSide => ss.reverse ? flipped : !flipped;

  @override
  void dispose() {
    answer.dispose();
    answerFocus.dispose();
    super.dispose();
  }

  void markHard(CardItem c) {
    AppScope.read(context).markHard(c, review: ss.review);
    ss.hard.add(c.key);
    // So'z 3 ta kartadan keyin yana chiqadi.
    ss.deck.insert(min(ss.deck.length, ss.pos + 4), c);
  }

  void markEasy(CardItem c) {
    AppScope.read(context).markEasy(c, review: ss.review);
    ss.easy++;
  }

  void grade(bool easy) {
    easy ? markEasy(card) : markHard(card);
    next();
  }

  void next() {
    ss.pos++;
    flipped = false;
    answered = null;
    answer.clear();
    if (ss.pos >= ss.deck.length) {
      finish();
      return;
    }
    setState(() {});
    if (ss.typing) answerFocus.requestFocus();
  }

  Future<void> finish() async {
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

  void tapCard() {
    // Faqat inglizcha tomonda ovoz chiqadi.
    if (!enSide) return;
    Speech.speak(card.word.en);
    setState(() => pulse = true);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => pulse = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(card.book);
    final mode = ss.review ? 'Takrorlash' : ss.typing ? 'Yozish' : 'Kartalar';
    return Scaffold(
      appBar: TopBar(
          title: ss.unitLabel, book: b, subtitle: '$mode · ${min(ss.pos + 1, ss.deck.length)}/${ss.deck.length}'),
      bottomNavigationBar: s.isPremium ? null : const SafeArea(top: false, child: AdBanner()),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: ss.pos / ss.deck.length, minHeight: 7, color: C.gold, backgroundColor: C.sf2),
          ),
        ),
        Expanded(child: ss.typing ? _typing() : _cards()),
      ]),
    );
  }

  Widget _cards() {
    final w = card.word;
    final en = enSide;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(children: [
        Expanded(
          child: Semantics(
            button: true,
            label: en ? 'Bosing: talaffuz' : 'Karta',
            child: GestureDetector(
              onTap: tapCard,
              child: AnimatedScale(
                scale: pulse ? .98 : 1,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: en ? C.grad : null,
                    color: en ? null : C.sf2,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: pulse ? Colors.white54 : (en ? Colors.transparent : C.ln), width: 2),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Column(children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(en ? 'INGLIZCHA' : "O'ZBEKCHA",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .9,
                              color: (en ? Colors.white : C.fg).withValues(alpha: .75))),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(en ? w.en : w.uz,
                              textAlign: TextAlign.center,
                              style: display(34, color: en ? Colors.white : C.fg)),
                          const SizedBox(height: 10),
                          if (en && w.ipa.isNotEmpty)
                            Text(w.ipa, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                          if (!en && w.ex.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(w.ex,
                                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: C.mut)),
                            ),
                        ]),
                      ),
                    ),
                    Text(en ? "Kartaning istalgan joyini bosing: talaffuz" : "Bu tomonda bosganda ovoz chiqmaydi",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: (en ? Colors.white : C.mut).withValues(alpha: .8))),
                    const SizedBox(height: 10),
                    // Aylantirish tugmasi kartaning ichida, to'liq enida.
                    Material(
                      color: en ? Colors.black26 : C.sf,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: en ? BorderSide.none : const BorderSide(color: C.ac, width: 1.5)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => flipped = !flipped),
                        child: SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.sync_rounded, color: en ? Colors.white : C.ac, size: 26),
                            const SizedBox(width: 10),
                            Text('Aylantirish',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16, color: en ? Colors.white : C.fg)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: _gradeBtn('Qiyin', ss.review ? 'ertaga yana' : "yana ko'rsatiladi", C.bad, () => grade(false))),
          const SizedBox(width: 12),
          Expanded(child: _gradeBtn('Oson', ss.review ? 'keyingi bosqich' : 'yodladim', C.good, () => grade(true))),
        ]),
      ]),
    );
  }

  Widget _gradeBtn(String t, String sub, Color c, VoidCallback onTap) => Material(
        color: C.sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c, width: 2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 66,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(sub, style: const TextStyle(color: C.mut, fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _typing() {
    final w = card.word;
    final promptEn = !ss.reverse;
    final a = answered;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
      GestureDetector(
        onTap: promptEn ? () => Speech.speak(w.en) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            gradient: promptEn ? C.grad : null,
            color: promptEn ? null : C.sf2,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Text(promptEn ? "O'zbekchasini yozing" : 'Inglizchasini yozing',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: (promptEn ? Colors.white : C.fg).withValues(alpha: .85))),
            const SizedBox(height: 10),
            Text(promptEn ? w.en : w.uz,
                textAlign: TextAlign.center, style: display(32, color: promptEn ? Colors.white : C.fg)),
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
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
            style: TextStyle(color: a.ok ? C.good : C.bad, fontWeight: FontWeight.w800, fontSize: 16)),
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

class DoneScreen extends StatelessWidget {
  final Session session;
  const DoneScreen({super.key, required this.session});
  @override
  Widget build(BuildContext context) {
    final ss = session;
    final hardN = ss.hard.length;
    final xp = ss.review ? ss.easy * 5 : ss.easy * 10;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 40, 16, 24), children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: C.grad),
              child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
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
          const SizedBox(height: 16),
          Btn('Davom etish', onTap: () => Navigator.of(context).pop()),
          const SizedBox(height: 10),
          Btn('Qaytarish (hammasini qayta)',
              kind: BtnKind.ghost,
              onTap: () => startSession(context, ss.src, review: ss.review, typing: ss.typing, reverse: ss.reverse, replace: true)),
          const SizedBox(height: 10),
          Btn("Qiyinlarini qayta ko'rish${hardN > 0 ? ' ($hardN)' : ''}",
              kind: BtnKind.ghost,
              onTap: hardN == 0
                  ? null
                  : () => startSession(context, ss.src.where((c) => ss.hard.contains(c.key)).toList(),
                      review: ss.review, typing: ss.typing, reverse: ss.reverse, replace: true)),
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
