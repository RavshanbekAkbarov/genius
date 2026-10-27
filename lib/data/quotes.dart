/// Motivatsion gaplar: faqat muallifi aniq tasdiqlangan iqtiboslar (manba izohda).
class Quote {
  final String en;
  final String uz;
  final String author;
  const Quote(this.en, this.uz, this.author);
}

const quotes = <Quote>[
  // Nelson Mandela, Mindset Network nutqi, 2003
  Quote('Education is the most powerful weapon which you can use to change the world.',
      "Ta'lim dunyoni o'zgartirish uchun ishlatishingiz mumkin bo'lgan eng kuchli quroldir.", 'Nelson Mandela'),
  // Albert Einstein, The Saturday Evening Post intervyusi, 1929
  Quote('Imagination is more important than knowledge.', "Tasavvur bilimdan muhimroq.", 'Albert Einstein'),
  // Albert Einstein, o'g'li Eduardga maktub, 1930
  Quote('Life is like riding a bicycle. To keep your balance you must keep moving.',
      "Hayot velosiped haydashga o'xshaydi. Muvozanatni saqlash uchun to'xtamay harakatlanish kerak.",
      'Albert Einstein'),
  // Thomas Edison, 1903 yildagi suhbat (Harper's Monthly, 1932)
  Quote('Genius is one percent inspiration, ninety-nine percent perspiration.',
      "Daho bir foiz ilhom va to'qson to'qqiz foiz mehnatdir.", 'Thomas Edison'),
  // Isaac Newton, Robert Hukka maktub, 1675
  Quote('If I have seen further, it is by standing on the shoulders of giants.',
      "Agar men uzoqroqni ko'rgan bo'lsam, bu gigantlarning yelkasida turganim uchundir.", 'Isaac Newton'),
  // Ludwig Wittgenstein, "Tractatus Logico-Philosophicus", 5.6
  Quote('The limits of my language mean the limits of my world.',
      "Tilimning chegaralari dunyoimning chegaralaridir.", 'Ludwig Wittgenstein'),
  // Will Durant, "The Story of Philosophy", 1926
  Quote('We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      "Biz takror-takror qiladigan ishimizmiz. Demak, mukammallik bir martalik ish emas, odatdir.", 'Will Durant'),
  // Steve Jobs, Stanford universiteti nutqi, 2005
  Quote('The only way to do great work is to love what you do.',
      "Buyuk ish qilishning yagona yo'li qilayotgan ishingizni sevishdir.", 'Steve Jobs'),
  // Steve Jobs, Stanford universiteti nutqi, 2005
  Quote("Your time is limited, so don't waste it living someone else's life.",
      "Vaqtingiz cheklangan, uni boshqa birovning hayotini yashab o'tkazmang.", 'Steve Jobs'),
  // Steve Jobs, Stanford universiteti nutqi, 2005 (Whole Earth Catalog'dan)
  Quote('Stay hungry. Stay foolish.', "Doim och bo'ling. Doim sodda bo'ling.", 'Steve Jobs'),
  // Malcolm X, OAAU yig'ilishi nutqi, 1964
  Quote('Education is our passport to the future, for tomorrow belongs to the people who prepare for it today.',
      "Ta'lim kelajakka pasportimiz, chunki ertangi kun unga bugun tayyorlanayotganlarniki.", 'Malcolm X'),
  // Michael Jordan, Nike "Failure" reklamasi, 1997
  Quote("I've failed over and over and over again in my life. And that is why I succeed.",
      "Hayotimda qayta-qayta yutqazganman. Aynan shuning uchun muvaffaqiyatga erishaman.", 'Michael Jordan'),
  // John F. Kennedy, Dallas uchun tayyorlangan nutq, 1963
  Quote('Leadership and learning are indispensable to each other.',
      "Yetakchilik va o'rganish bir-birisiz bo'lmaydi.", 'John F. Kennedy'),
  // Aristotel, Diogen Laertiy "Mashhur faylasuflar hayoti" kitobida keltirgan
  Quote('The roots of education are bitter, but the fruit is sweet.',
      "Ilmning ildizi achchiq, ammo mevasi shirin.", 'Aristotel'),
  // Seneka, Lutsiliyga maktublar, 7-maktub
  Quote('While we teach, we learn.', "Biz o'rgatayotib o'rganamiz.", 'Seneka'),
  // Richard Feynman, "What Do You Care What Other People Think?", 1988
  Quote('I learned very early the difference between knowing the name of something and knowing something.',
      "Men juda erta bir narsaning nomini bilish bilan o'sha narsani bilish orasidagi farqni tushunganman.",
      'Richard Feynman'),
  // Lao Szi, "Dao De Szin", 64-bob
  Quote('A journey of a thousand miles begins with a single step.',
      "Ming chaqirimlik yo'l bitta qadamdan boshlanadi.", 'Lao Szi'),
  // Yapon xalq maqoli
  Quote('Fall seven times, stand up eight.', "Yetti marta yiqilsang, sakkiz marta tur.", 'Yapon maqoli'),
];

/// Kunning gapi: har kuni boshqa, [slot] bilan kuniga ikkinchisini ham olish mumkin.
Quote quoteOfDay(DateTime day, {int slot = 0}) {
  final n = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays;
  return quotes[(n * 2 + slot) % quotes.length];
}
