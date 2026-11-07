import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genius/data/quotes.dart';
import 'package:genius/data/stories.dart';
import 'package:genius/data/words.dart';
import 'package:genius/services/word_widget.dart';
import 'package:genius/main.dart';
import 'package:genius/screens/books.dart';
import 'package:genius/screens/listen.dart';
import 'package:genius/screens/offline.dart';
import 'package:genius/screens/profile.dart';
import 'package:genius/screens/schedule.dart';
import 'package:genius/screens/setup.dart';
import 'package:genius/screens/story.dart';
import 'package:genius/screens/study.dart';
import 'package:genius/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Har bir oyna xatosiz chiziladimi (telefon o'lchamida, sig'masa xato chiqadi).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppState s;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WordBank.load();
    await StoryBank.load();
    s = AppState();
    await s.load();
    s.seedDemo();
  });

  Future<void> show(WidgetTester t, Widget page) async {
    t.view.physicalSize = const Size(1080, 2280);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(GeniusApp(state: s));
    await t.pump();
    if (page is! SizedBox) {
      Navigator.of(t.element(find.byType(Scaffold).first)).push(MaterialPageRoute(builder: (_) => page));
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('bosh sahifa va bo\'limlar', (t) async {
    await show(t, const SizedBox());
    expect(find.text('Bugungi mashq'), findsOneWidget);
    for (final tab in ['Kitoblar', "Do'kon", 'Profil']) {
      await t.tap(find.text(tab).last);
      await t.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Eng uzun seriyalar'), findsOneWidget);
  });

  testWidgets('unit oynasi', (t) async => show(t, const UnitScreen(bookId: 'e1', unit: 1)));
  testWidgets('mashq sozlamalari', (t) async => show(t, const SetupScreen(bookId: 'e1')));
  testWidgets('tinglash', (t) async => show(t, const ListenScreen(bookId: 'e1')));
  testWidgets('jadval', (t) async => show(t, const ScheduleScreen()));
  testWidgets('internetsiz', (t) async => show(t, const OfflineScreen()));
  testWidgets('premium', (t) async => show(t, const PremiumScreen()));
  testWidgets('profil tahrirlash', (t) async => show(t, const ProfileEditScreen()));

  testWidgets('kartalar: aylantirish va baholash', (t) async {
    final w = s.words('e1', 4);
    final list = [for (var i = 0; i < 3; i++) CardItem(wkey('e1', 4, i), 'e1', 4, w[i])];
    await show(t, StudyScreen(session: Session(list, review: false, typing: false, reverse: false)));
    await t.tap(find.text('Aylantirish').first);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Oson'));
    await t.pump(const Duration(milliseconds: 600));
    expect(s.learned(wkey('e1', 4, 0)), isTrue);
  });

  testWidgets('yozish', (t) async {
    final w = s.words('e1', 4);
    await show(t, StudyScreen(session: Session([CardItem(wkey('e1', 4, 0), 'e1', 4, w[0])], review: false, typing: true, reverse: false)));
  });

  testWidgets('katta shrift (1.3x) bilan ham sig\'adi', (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await show(t, const SizedBox());
    for (final tab in ['Kitoblar', "Do'kon", 'Profil']) {
      await t.tap(find.text(tab).last);
      await t.pump(const Duration(milliseconds: 400));
    }
    final w = s.words('e1', 4);
    await show(t, StudyScreen(session: Session([CardItem(wkey('e1', 4, 0), 'e1', 4, w[0])], review: false, typing: false, reverse: false)));
    await show(t, const SetupScreen(bookId: 'e1'));
    await show(t, const UnitScreen(bookId: 'e1', unit: 1));
  });

  test('admin paneldagi kun so\'zi va iqtiboslar ishlatiladi', () {
    addTearDown(() => remoteQuotes = []);
    final before = wordOfDay(s).en;
    s.setDaily([const Quote('Keep going.', 'Davom eting.', 'Test')], {ds(s.today): const Word('zebra', 'zebra', '')});
    expect(wordOfDay(s).en, 'zebra');
    expect(wordOfDay(s, addDays(s.today, 1)).en, isNot('zebra'));
    expect(s.quote.author, 'Test');
    s.setDaily([], {});
    expect(wordOfDay(s).en, before);
    expect(quotes.contains(s.quote), isTrue);
  });

  test('hikoya lug\'ati: istalgan so\'z shakli topiladi', () {
    expect(StoryBank.of('e1', 1)!.title, 'The Lion and the Rabbit');
    expect(StoryBank.of('e1', 30), isNotNull);
    final s1 = StoryBank.of('e1', 1)!;
    final pi = s1.paras.indexWhere((p) => p.contains('Why are you late'));
    final at = s1.paras[pi].indexOf('late');
    expect(s1.sentenceAt(pi, at), 'The lion angrily asked the rabbit, “Why are you late?”');
    expect(s1.trAt(pi, at), contains('Nega kechikding'));
    expect(StoryBank.lookup('jumped')!.lemma, 'jump');
    expect(StoryBank.lookup('rabbit’s')!.lemma, 'rabbit');
    expect(StoryBank.lookup('Clever')!.syn, contains('smart'));
    expect(StoryBank.lookup('arrived')!.uz, isNotEmpty);
    // Har bir hikoyadagi har bir so'z lug'atda bor.
    final re = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?");
    for (var b = 1; b <= 6; b++) {
      for (var u = 1; u <= 30; u++) {
        final st = StoryBank.of('e$b', u)!;
        expect(st.qs.length, inInclusiveRange(3, 6), reason: 'e$b|$u');
        if (st.tr.isNotEmpty) {
          final n = st.paras.fold<int>(0, (a, p) => a + Story.spans(p).length);
          expect(st.tr.length, n, reason: '$b|$u: gaplar tarjimasi soni');
        }
        for (final q in st.qs) {
          expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: 'e$b|$u: ${q.q}');
        }
        for (final p in st.paras) {
          for (final m in re.allMatches(p)) {
            final w = m.group(0)!;
            if (w.length == 1 && w != 'a' && w != 'A' && w != 'I') continue;
            expect(StoryBank.lookup(w), isNotNull, reason: 'e$b|$u: $w');
          }
        }
      }
    }
  });

  testWidgets('hikoya: o\'qish, so\'z oynasi va savollar', (t) async {
    await show(t, const UnitScreen(bookId: 'e1', unit: 1));
    expect(find.text('The Lion and the Rabbit'), findsOneWidget);
    await show(t, const StoryScreen(bookId: 'e1', unit: 1));
    expect(find.text('The Lion and the Rabbit'), findsOneWidget);
    await t.dragUntilVisible(find.textContaining('Tugatdim'), find.byType(ListView).last, const Offset(0, -600));
    await t.pump();
    await t.tap(find.textContaining('Tugatdim'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Tushundingizmi?'), findsOneWidget);
    expect(s.storiesRead, contains('e1|1'));
    await t.tap(find.text('How a clever rabbit tricked a cruel lion'));
    await t.pump();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('so\'z oynasi', (t) async {
    await show(t, const SizedBox());
    showModalBottomSheet(
        context: t.element(find.byType(Scaffold).first),
        isScrollControlled: true,
        builder: (_) => WordSheet(
            token: 'clever', entry: StoryBank.lookup('clever'), sentence: 'He is not clever.', unitLabel: "Unit 1 so'zi"));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('SINONIMLAR'), findsOneWidget);
    await t.ensureVisible(find.textContaining("Mening so'zlarimga"));
    await t.pump();
    await t.tap(find.textContaining("Mening so'zlarimga"));
    await t.pump();
    expect(s.hasMyWord('clever'), isTrue);
  });
}
