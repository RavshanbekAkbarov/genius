import 'package:flutter_test/flutter_test.dart';
import 'package:genius/data/catalog.dart';
import 'package:genius/data/quotes.dart';
import 'package:genius/data/words.dart';
import 'package:genius/services/reminders.dart';
import 'package:genius/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppState> fresh() async {
    final s = AppState();
    await s.load();
    return s;
  }

  CardItem card(String b, int u, int i) => CardItem(wkey(b, u, i), b, u, Word('w$i', "so'z$i"));

  test("yangi o'rnatilgan ilovada namuna ma'lumot yo'q", () async {
    final s = await fresh();
    expect(s.isFresh, isTrue);
    expect(s.streak, 0);
  });

  test("namuna: takror jadvali va olov", () async {
    final s = await fresh();
    s.seedDemo();
    expect(s.streak, greaterThan(0));
    expect(s.dueGroups.map((g) => '${g.book}|${g.unit}').toSet(), {'e1|1', 'e1|2'});
    // Kechikkan unit birinchi turadi.
    expect(s.dueGroups.first.late, isTrue);
  });

  test("takror: Oson keyingi bosqichga, Qiyin 1-kunga qaytaradi", () async {
    final s = await fresh();
    s.seedDemo();
    final c = card('e1', 2, 0);
    s.markEasy(c, review: true);
    expect(s.prog[c.key]!.stage, 2);
    expect(s.prog[c.key]!.due, ds(addDays(s.today, intervals[2] - intervals[1])));
    s.markHard(c, review: true);
    expect(s.prog[c.key]!.stage, 0);
    expect(s.prog[c.key]!.due, ds(addDays(s.today, 1)));
  });

  test("kechikkan takror o'z kuniga yoziladi, keyingi sana asl sanadan", () async {
    final s = await fresh();
    final yesterday = addDays(s.today, -1);
    final c = card('e1', 5, 0);
    s.prog[c.key] = Prog(learned: true, stage: 1, due: ds(yesterday)); // 3-kun takrori kecha edi
    s.markEasy(c, review: true);
    // 7-kun takrori: kecha + 4 kun = bugundan 3 kun keyin (bugun + 4 emas).
    expect(s.prog[c.key]!.due, ds(addDays(yesterday, intervals[2] - intervals[1])));
    expect(s.dayOf(yesterday)!.reviewUnits, contains('e1|5'));
    expect(s.dayOf(yesterday)!.lateUnits['e1|5'], s.td);
    expect(s.dayOf(s.today)!.reviewedUnits, contains('e1|5'));
    // Olov bugungi kun uchun hisoblanadi.
    expect(s.active(s.today), isTrue);
  });

  test("juda kechikkan takror: keyingi sana ertadan oldin bo'lmaydi", () async {
    final s = await fresh();
    final c = card('e1', 6, 0);
    s.prog[c.key] = Prog(learned: true, stage: 0, due: ds(addDays(s.today, -10)));
    s.markEasy(c, review: true);
    expect(s.prog[c.key]!.due, ds(addDays(s.today, 1)));
  });

  test("yangi so'z kunlik tafsilotga yoziladi", () async {
    final s = await fresh();
    s.logSession();
    s.markEasy(card('e1', 1, 0), review: false);
    s.markHard(card('e1', 1, 1), review: false);
    final d = s.dayOf(s.today)!;
    expect(d.newWords, 1);
    expect(d.newUnits, {'e1|1'});
    expect(d.sessions, 1);
    expect(d.accuracy, 50);
  });

  test("bepul limit: kuniga $freeSessions ta, keyin 0", () async {
    final s = await fresh();
    for (var i = 0; i < freeSessions; i++) {
      s.useSession();
    }
    expect(s.sessionsLeft, 0);
    s.activatePremium(30);
    expect(s.sessionsLeft, greaterThan(1000));
  });

  test("internetsiz kuniga $offlineSessions ta mashq", () async {
    final s = await fresh();
    for (var i = 0; i < offlineSessions; i++) {
      s.useOffline();
    }
    expect(s.offlineLeft, 0);
    s.shiftDays(1);
    expect(s.offlineLeft, offlineSessions);
  });

  test("Teskari va harf o'lchami saqlanadi", () async {
    final s = await fresh();
    s.setReverse(true);
    s.bumpFont(1);
    final again = await fresh();
    expect(again.reverse, isTrue);
    expect(again.fontScale, closeTo(1.1, .001));
  });

  test("Mening so'zlarim: har 20 ta so'z bitta unit", () async {
    final s = await fresh();
    for (var i = 0; i < 21; i++) {
      s.addMyWord(Word('w$i', "so'z$i"));
    }
    expect(s.unitsOf(bookById(myBookId)), 2);
    expect(s.words(myBookId, 2).single.en, 'w20');
    expect(s.hasMyWord('W3'), isTrue);
  });

  test('eng uzun seriyalar', () async {
    final s = await fresh();
    for (final n in [1, 2, 3, 6, 7]) {
      s.log[ds(addDays(s.today, -n))] = 5;
    }
    final best = s.bestStreaks();
    expect(best.first.length, 3);
    expect(best[1].length, 2);
  });

  test("eslatmalar: kuniga ko'pi bilan 4 ta, bajarilsa kamayadi", () async {
    final s = await fresh();
    s.seedDemo();
    final today = Reminders.plan(s, 0);
    expect(today.length, lessThanOrEqualTo(4));
    // Namunada bugun hali mashq yo'q: 20:00 va 21:30 bor.
    expect(today.map((e) => e.$1), containsAll([8, 14, 20, 21]));
    s.markEasy(card('e1', 2, 0), review: true);
    final after = Reminders.plan(s, 0);
    expect(after.map((e) => e.$1), isNot(contains(20)));
    expect(after.where((e) => e.$1 == 14).single.$3, contains('tasini bajardingiz'));
  });

  test('server nusxasidan tiklash', () async {
    final s = await fresh();
    s.markEasy(card('e1', 1, 0), review: false);
    final copy = s.progressJson();
    final other = await fresh();
    other.resetAll();
    other.restoreProgress(copy);
    expect(other.learned(wkey('e1', 1, 0)), isTrue);
  });

  test('javobni solishtirish apostroflarni bir xil ko\'radi', () {
    expect(normalize(' Qo‘rqqan '), normalize("qo'rqqan"));
  });

  test('kunning gapi har kuni boshqa', () {
    final a = quoteOfDay(DateTime(2026, 10, 17));
    final b = quoteOfDay(DateTime(2026, 10, 18));
    expect(a.en, isNot(b.en));
    expect(quoteOfDay(DateTime(2026, 10, 17), slot: 1).en, isNot(a.en));
  });
}
