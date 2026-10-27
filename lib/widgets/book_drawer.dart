import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/scope.dart';
import '../theme.dart';
import 'common.dart';

/// ☰ menyusi: kitobni tanlash. Tanlangan kitob tepada turadi va bosh sahifa ochiladi.
class BookDrawer extends StatelessWidget {
  final VoidCallback onPicked;
  const BookDrawer({super.key, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget item(Book b) {
      final sel = b.id == s.currentBook;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Material(
          color: sel ? C.sf2 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: BookBadge(b, size: 22),
            title: Text(b.title,
                style: TextStyle(fontWeight: FontWeight.w800, color: sel ? C.ac : C.fg, fontSize: 15)),
            trailing: Text(b.isMine ? "${s.myWords.length} so'z" : '${s.bookPct(b.id)}%',
                style: const TextStyle(color: C.mut, fontSize: 12, fontWeight: FontWeight.w700)),
            onTap: () {
              s.pickBook(b.id);
              Navigator.pop(context);
              onPicked();
              toast(context, '${b.title} tanlandi');
            },
          ),
        ),
      );
    }

    Widget label(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Eyebrow(t),
        );

    return Drawer(
      backgroundColor: C.sf,
      child: ListView(padding: EdgeInsets.zero, children: [
        Container(
          decoration: const BoxDecoration(gradient: C.grad),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kitobni tanlang', style: display(19, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Tanlangan kitob tepada turadi', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
        label('Shaxsiy'),
        ...booksOf(BookGroup.personal).map(item),
        label('4000 Essential Words'),
        ...booksOf(BookGroup.essential).map(item),
        label('Markaz kitoblari'),
        ...booksOf(BookGroup.center).map(item),
        const SizedBox(height: 20),
      ]),
    );
  }
}
