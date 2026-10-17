import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genius/data/words.dart';
import 'package:genius/main.dart';
import 'package:genius/screens/books.dart';
import 'package:genius/screens/listen.dart';
import 'package:genius/screens/offline.dart';
import 'package:genius/screens/profile.dart';
import 'package:genius/screens/schedule.dart';
import 'package:genius/screens/setup.dart';
import 'package:genius/screens/study.dart';
import 'package:genius/state/app_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Har bir oyna xatosiz chiziladimi (telefon o'lchamida, sig'masa xato chiqadi).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  late AppState s;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WordBank.load();
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
    for (final tab in ['Kitoblar', 'Reyting', "Do'kon", 'Profil']) {
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
    await t.tap(find.byType(FlipCard).first);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Oson'));
    await t.pump(const Duration(milliseconds: 600));
    expect(s.learned(wkey('e1', 4, 0)), isTrue);
  });

  testWidgets('yozish', (t) async {
    final w = s.words('e1', 4);
    await show(t, StudyScreen(session: Session([CardItem(wkey('e1', 4, 0), 'e1', 4, w[0])], review: false, typing: true, reverse: false)));
  });
}
