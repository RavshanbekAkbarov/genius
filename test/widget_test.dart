import 'package:flutter_test/flutter_test.dart';
import 'package:genius/data/catalog.dart';
import 'package:genius/data/words.dart';
import 'package:genius/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test("namuna ma'lumot: takror jadvali va olov", () async {
    final s = AppState();
    await s.load();
    expect(s.streak, greaterThan(0));
    // Essential 1 Unit 1 (kechikkan) va Unit 2 (bugun) takrorda turadi.
    expect(s.dueGroups.map((g) => '${g.book}|${g.unit}').toSet(), {'e1|1', 'e1|2'});
  });

  test("takror: Oson keyingi bosqichga, Qiyin 1-kunga qaytaradi", () async {
    final s = AppState();
    await s.load();
    final k = wkey('e1', 2, 0);
    final c = CardItem(k, 'e1', 2, const Word('alone', "yolg'iz"));
    s.markEasy(c, review: true);
    expect(s.prog[k]!.stage, 2);
    expect(s.prog[k]!.due, ds(addDays(s.today, intervals[2] - intervals[1])));
    s.markHard(c, review: true);
    expect(s.prog[k]!.stage, 0);
    expect(s.prog[k]!.due, ds(addDays(s.today, 1)));
  });

  test("bepul limit: kuniga $freeSessions ta, keyin 0", () async {
    final s = AppState();
    await s.load();
    for (var i = 0; i < freeSessions; i++) {
      s.useSession();
    }
    expect(s.sessionsLeft, 0);
    s.activatePremium(30);
    expect(s.sessionsLeft, greaterThan(1000));
  });

  test("Mening so'zlarim: har 20 ta so'z bitta unit", () async {
    final s = AppState();
    await s.load();
    for (var i = 0; i < 21; i++) {
      s.addMyWord(Word('w$i', "so'z$i"));
    }
    expect(s.unitsOf(bookById(myBookId)), 2);
    expect(s.words(myBookId, 2).single.en, 'w20');
    expect(s.hasMyWord('W3'), isTrue);
  });

  test('javobni solishtirish apostroflarni bir xil ko\'radi', () {
    expect(normalize(' Qo‘rqqan '), normalize("qo'rqqan"));
  });
}
