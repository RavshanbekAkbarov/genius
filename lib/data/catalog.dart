import 'package:flutter/material.dart';

/// Takrorlash oraliqlari (kunlarda): yodlangandan keyin 1, 3, 7, 15, 30-kun.
const intervals = [1, 3, 7, 15, 30];

/// Bepul foydalanuvchi uchun kunlik mashq soni. Takrorlar bu limitga kirmaydi.
const freeSessions = 8;

/// Kunlik maqsad (so'z).
const dailyGoal = 20;

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

  const Book(this.id, this.badge, this.title, this.fixedUnits, this.colors, this.group);

  bool get isMine => id == myBookId;
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
  Book('beg', 'A1', 'Beginner', 20, [Color(0xFFFFB347), Color(0xFFF07B1D)], BookGroup.center),
  Book('fou', 'A2', 'Foundation', 20, [Color(0xFFFF8A65), Color(0xFFD84B2A)], BookGroup.center),
  Book('pre', 'B1', 'Pre-IELTS', 20, [Color(0xFF7E8CFF), Color(0xFF4B55C9)], BookGroup.center),
];

Book bookById(String id) => books.firstWhere((b) => b.id == id, orElse: () => books[1]);

class IeltsBook {
  final String id;
  final String badge;
  final String title;
  final List<Color> colors;
  final int readPrice, wordsPrice, bothPrice;
  const IeltsBook(this.id, this.badge, this.title, this.colors, this.readPrice, this.wordsPrice, this.bothPrice);
  LinearGradient get gradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors);
}

const ieltsBooks = <IeltsBook>[
  IeltsBook('ie1', 'I', 'IELTS kitobi 1', [Color(0xFFC9334F), Color(0xFF7D1530)], 39000, 19000, 49000),
  IeltsBook('ie2', 'II', 'IELTS kitobi 2', [Color(0xFF304A6E), Color(0xFF16243A)], 39000, 19000, 49000),
];

/// XP bo'yicha unvonlar.
const titles = <(int, String)>[
  (0, 'Yangi boshlovchi'),
  (100, "O'quvchi"),
  (500, 'Bilimdon'),
  (1500, 'Ustoz'),
  (4000, "Lug'at ustasi"),
];

/// Reyting uchun namuna ishtirokchilar: [bugun, hafta, oy, umumiy]. Haqiqiy reyting serverdan keladi.
const samplePeople = <(String, List<int>)>[
  ('Madina R.', [38, 190, 720, 4100]),
  ('Jasur T.', [31, 214, 650, 3820]),
  ('Sevara K.', [27, 160, 700, 2950]),
  ('Bekzod A.', [24, 140, 540, 2600]),
  ('Dilnoza M.', [19, 120, 480, 2210]),
  ('Sardor N.', [15, 98, 410, 1980]),
  ('Malika Y.', [12, 85, 300, 1500]),
  ('Otabek S.', [9, 60, 250, 1100]),
  ('Nigora F.', [6, 44, 190, 870]),
  ('Azizbek O.', [4, 30, 120, 640]),
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
