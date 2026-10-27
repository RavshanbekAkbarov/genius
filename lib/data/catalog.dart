import 'package:flutter/material.dart';

/// Takrorlash oraliqlari (kunlarda): yodlangandan keyin 1, 3, 7, 15, 30-kun.
const intervals = [1, 3, 7, 15, 30];

/// Bepul foydalanuvchi uchun kunlik mashq soni. Takrorlar bu limitga kirmaydi.
const freeSessions = 8;

/// Kunlik maqsad (so'z), foydalanuvchi profilda o'zgartirmaguncha.
const defaultDailyGoal = 20;

/// Internetsiz kuniga ruxsat etilgan mashqlar (Premium'da cheklov yo'q).
const offlineSessions = 3;

/// Premium narxi, so'm/oy.
const premiumPrice = 10000;

/// "Mening so'zlarim" kitobining id si.
const myBookId = 'my';

enum BookGroup { personal, essential, center }

class Book {
  final String id;
  final String badge;
  final String title;
  final int fixedUnits;
  final List<Color> colors;
  final BookGroup group;

  /// Markaz kitobi narxi (so'm). 0 bo'lsa bepul.
  final int price;

  /// Serverdan (admin paneldan) kelgan kitob.
  final bool remote;

  const Book(this.id, this.badge, this.title, this.fixedUnits, this.colors, this.group,
      {this.price = 0, this.remote = false});

  bool get isMine => id == myBookId;
  bool get paid => price > 0;

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        j['id'] as String,
        (j['badge'] ?? 'A1') as String,
        (j['title'] ?? '') as String,
        (j['units'] ?? 20) as int,
        [_hex(j['color1'] as String?, 0xFFFFB347), _hex(j['color2'] as String?, 0xFFF07B1D)],
        BookGroup.center,
        price: (j['price'] ?? 0) as int,
        remote: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'badge': badge,
        'title': title,
        'units': fixedUnits,
        'color1': '#${(colors[0].toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
        'color2': '#${(colors[1].toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
        'price': price,
      };
  LinearGradient get gradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors);
}

const books = <Book>[
  Book(myBookId, '★', "Mening so'zlarim", 1, [Color(0xFFFFD166), Color(0xFFE09A1C)], BookGroup.personal),
  Book('e1', '1', 'Essential 1', 30, [Color(0xFF3FBF6B), Color(0xFF1C8A4A)], BookGroup.essential),
  Book('e2', '2', 'Essential 2', 30, [Color(0xFFF05F9A), Color(0xFFC23476)], BookGroup.essential),
  Book('e3', '3', 'Essential 3', 30, [Color(0xFF4A8FF0), Color(0xFF2357B8)], BookGroup.essential),
  Book('e4', '4', 'Essential 4', 30, [Color(0xFFB35BE0), Color(0xFF7A2FA8)], BookGroup.essential),
  Book('e5', '5', 'Essential 5', 30, [Color(0xFF2FA3A0), Color(0xFF1A6F6D)], BookGroup.essential),
  Book('e6', '6', 'Essential 6', 30, [Color(0xFF3A5FD9), Color(0xFF1F3596)], BookGroup.essential),
];

Color _hex(String? s, int fallback) {
  final v = int.tryParse((s ?? '').replaceFirst('#', ''), radix: 16);
  return Color(v == null ? fallback : 0xFF000000 | v);
}

/// Markaz kitoblari: admin paneldan qo'shiladi va serverdan keladi.
List<Book> remoteBooks = [];

List<Book> get allBooks => [...books, ...remoteBooks];
List<Book> booksOf(BookGroup g) => allBooks.where((b) => b.group == g).toList();

Book bookById(String id) => allBooks.firstWhere((b) => b.id == id, orElse: () => books[1]);

/// XP bo'yicha unvonlar.
const titles = <(int, String)>[
  (0, 'Yangi boshlovchi'),
  (100, "O'quvchi"),
  (500, 'Bilimdon'),
  (1500, 'Ustoz'),
  (4000, "Lug'at ustasi"),
];

const months = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
const weekdays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

String money(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

const monthsFull = [
  'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'
];
const weekdaysFull = ['dushanba', 'seshanba', 'chorshanba', 'payshanba', 'juma', 'shanba', 'yakshanba'];

/// "17-oktabr, juma"
String dayLabel(DateTime d) => '${d.day}-${monthsFull[d.month - 1]}, ${weekdaysFull[d.weekday - 1]}';

/// "17-okt"
String shortDate(DateTime d) => '${d.day}-${months[d.month - 1].toLowerCase()}';
