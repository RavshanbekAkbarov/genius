/// So'zning matndagi shakliga mos o'zbekcha tarjima.
/// Lug'atda faqat asosiy shakl bor ("take" - "olmoq"), bu yerda esa matndagi
/// shaklga qarab qo'shimcha qo'shiladi: took - oldi, have taken - olgan,
/// was taken - olingan, takes - oladi, taking - olayotgan, books - kitoblar.
library;

const _be = {'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', "i'm", "it's", "he's", "she's", "that's", "isn't", "wasn't", "weren't", "aren't", 'get', 'got', 'gets', 'getting'};
const _have = {'have', 'has', 'had', 'having', "i've", "you've", "we've", "they've", "i'd", "you'd", "he'd", "she'd", "we'd", "they'd", "haven't", "hasn't", "hadn't"};
// Gapda ko'makchi fe'l bilan so'z orasida kelishi mumkin bo'lgan so'zlar.
const _skip = {'not', 'never', 'already', 'just', 'also', 'always', 'still', 'finally', 'really', 'even', 'all', 'often', 'recently', 'nearly', 'almost', 'quickly', 'suddenly', 'completely', 'carefully'};

/// Faqat sifatdosh (o'tgan zamon emas) bo'ladigan noto'g'ri fe'l shakllari.
const _participles = {
  'been', 'done', 'gone', 'taken', 'given', 'seen', 'known', 'eaten', 'fallen', 'written', 'broken', 'chosen',
  'spoken', 'stolen', 'forgotten', 'hidden', 'begun', 'shown', 'flown', 'grown', 'thrown', 'drawn', 'driven',
  'ridden', 'risen', 'worn', 'torn', 'woken', 'beaten', 'bitten', 'frozen', 'sung', 'swum', 'rung', 'drunk',
  'shaken', 'mistaken', 'forgiven', 'sworn', 'blown', 'sunk', 'gotten', 'proven', 'awoken',
};

/// Faqat o'tgan zamon bo'ladigan noto'g'ri fe'l shakllari.
const _pasts = {
  'was', 'were', 'did', 'went', 'took', 'gave', 'saw', 'knew', 'ate', 'fell', 'wrote', 'broke', 'chose', 'spoke',
  'stole', 'forgot', 'hid', 'began', 'showed', 'flew', 'grew', 'threw', 'drew', 'drove', 'rode', 'rose', 'wore',
  'tore', 'woke', 'bit', 'froze', 'sang', 'swam', 'rang', 'drank', 'shook', 'came', 'ran', 'became', 'forgave',
  'swore', 'blew', 'sank', 'sat', 'stood', 'lay',
};

const _vowels = 'aeiouAEIOU';

bool _endsVowel(String s) => s.isNotEmpty && _vowels.contains(s[s.length - 1]);

/// Fe'l o'zagi: "olmoq" -> "ol", "qabul qilmoq" -> "qabul qil". Fe'l bo'lmasa null.
String? _stem(String uz) => uz.endsWith('moq') && uz.length > 3 ? uz.substring(0, uz.length - 3) : null;

String _gan(String stem) {
  if (stem.endsWith('k')) return '${stem}kan';
  if (stem.endsWith('q')) return '${stem}qan';
  return '${stem}gan';
}

String _passive(String stem) {
  if (_endsVowel(stem)) return '${stem}l';
  if (stem.endsWith('l')) return '${stem}in';
  return '${stem}il';
}

/// Lug'atdagi tarjimaning birinchi ikki ma'nosi (vergul bilan ajratilgan).
List<String> _senses(String uz) {
  final cut = uz.split(';').first;
  return cut
      .split(',')
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty && !x.contains('(') && !x.startsWith('-'))
      .take(2)
      .toList();
}

/// Matndagi shaklning tarjimasi va izohi, yoki shakl asosiy so'zning o'zi bo'lsa null.
/// [prev]: so'zdan oldingi so'zlar, yaqinidan boshlab (kichik harflarda).
({String uz, String note})? contextForm(String token, String lemma, String uz, List<String> prev) {
  final t = token.toLowerCase().replaceAll('’', "'");
  if (t == lemma) return null;
  final senses = _senses(uz);
  if (senses.isEmpty) return null;

  // So'zdan oldingi ko'makchi fe'l (orada "not", "already" kabilar bo'lishi mumkin).
  String? aux;
  for (final w in prev) {
    if (_skip.contains(w)) continue;
    aux = w;
    break;
  }
  final afterBe = aux != null && _be.contains(aux);
  final afterHave = aux != null && _have.contains(aux);

  final verbs = [for (final s in senses) if (_stem(s) != null) _stem(s)!];
  if (verbs.isNotEmpty) {
    String out(String Function(String) f) => verbs.map(f).join(', ');
    if (t.endsWith('ing')) {
      return (
        uz: '${out((s) => _endsVowel(s) ? '${s}yotgan' : '${s}ayotgan')}; ${out((s) => _endsVowel(s) ? '${s}sh' : '${s}ish')}',
        note: '-ing shakli: hozir bo\'layotgan ish yoki ish nomi',
      );
    }
    final isParticiple = _participles.contains(t);
    final isPast = _pasts.contains(t) || t.endsWith('ed') || (!t.endsWith('s') && t != lemma);
    if (isParticiple || (isPast && (afterBe || afterHave))) {
      if (afterHave) return (uz: out(_gan), note: 'have/had + 3-shakl: bajarib bo\'lingan ish');
      return (uz: out((s) => _gan(_passive(s))), note: '3-shakl: ish unga nisbatan bajarilgan (majhul)');
    }
    if (t.endsWith('s') && t.length > lemma.length) {
      return (uz: out((s) => _endsVowel(s) ? '${s}ydi' : '${s}adi'), note: 'hozirgi zamon (u, bu)');
    }
    if (isPast) return (uz: out((s) => '${s}di'), note: 'o\'tgan zamon');
    return null;
  }

  // Ot, sifat.
  if (t.endsWith("'s")) {
    return (uz: senses.map((s) => '${s}ning').join(', '), note: "'s: qaratqich (kimning?)");
  }
  if (t.endsWith('est') || t == 'best' || t == 'worst' || t == 'most' || t == 'least') {
    return (uz: senses.map((s) => 'eng $s').join(', '), note: 'orttirma daraja');
  }
  if ((t.endsWith('er') && !lemma.endsWith('er')) || t == 'better' || t == 'worse' || t == 'more' || t == 'less') {
    return (uz: senses.map((s) => '${s}roq').join(', '), note: 'qiyosiy daraja');
  }
  if (t.endsWith('ly') && !lemma.endsWith('ly')) return null;
  if (t.endsWith('s') || t == 'men' || t == 'women' || t == 'children' || t == 'feet' || t == 'teeth' || t == 'mice') {
    return (uz: senses.map((s) => '${s}lar').join(', '), note: "ko'plik");
  }
  return null;
}
