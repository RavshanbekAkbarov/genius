import 'package:flutter_test/flutter_test.dart';
import 'package:genius/data/uzform.dart';

String? f(String t, String l, String uz, [List<String> prev = const []]) => contextForm(t, l, uz, prev)?.uz;

void main() {
  test('fe\'l shakllari gapga qarab tarjima qilinadi', () {
    expect(f('took', 'take', 'olmoq'), 'oldi');
    expect(f('taken', 'take', 'olmoq', ['have']), 'olgan');
    expect(f('taken', 'take', 'olmoq', ['was']), 'olingan');
    expect(f('takes', 'take', 'olmoq'), 'oladi');
    expect(f('taking', 'take', 'olmoq'), 'olayotgan; olish');
    expect(f('jumped', 'jump', 'sakramoq'), 'sakradi');
    expect(f('built', 'build', 'qurmoq', ['was']), 'qurilgan');
    expect(f('built', 'build', 'qurmoq', ['already', 'had']), 'qurgan');
    expect(f('reads', 'read', "o'qimoq"), "o'qiydi");
    expect(f('opened', 'open', 'ochmoq, qabul qilmoq'), 'ochdi, qabul qildi');
    expect(f('take', 'take', 'olmoq'), isNull);
  });
  test('ot va sifat shakllari', () {
    expect(f('books', 'book', 'kitob'), 'kitoblar');
    expect(f('rabbit’s', 'rabbit', 'quyon'), 'quyonning');
    expect(f('bigger', 'big', 'katta'), 'kattaroq');
    expect(f('biggest', 'big', 'katta'), 'eng katta');
  });
}
