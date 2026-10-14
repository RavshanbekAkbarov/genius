import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/words.dart';
import '../state/scope.dart';
import '../theme.dart';
import 'common.dart';

/// "Mening so'zlarim"ga so'z qo'shish yoki tahrirlash oynasi.
/// Qaysi kitobdan ochilmasin, so'z doim "Mening so'zlarim"ga saqlanadi.
Future<void> showAddWordSheet(BuildContext context, {int? editIndex, String? prefillEn}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.sf,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AddWordSheet(editIndex: editIndex, prefillEn: prefillEn),
  );
}

class _AddWordSheet extends StatefulWidget {
  final int? editIndex;
  final String? prefillEn;
  const _AddWordSheet({this.editIndex, this.prefillEn});
  @override
  State<_AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<_AddWordSheet> {
  final en = TextEditingController();
  final uz = TextEditingController();
  final ipa = TextEditingController();
  final ex = TextEditingController();
  final enFocus = FocusNode();
  final uzFocus = FocusNode();
  String? error;

  bool get editing => widget.editIndex != null;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    if (editing) {
      final w = s.myWords[widget.editIndex!];
      en.text = w.en;
      uz.text = w.uz;
      ipa.text = w.ipa;
      ex.text = w.ex;
    } else {
      en.text = widget.prefillEn ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => (en.text.isEmpty ? enFocus : uzFocus).requestFocus());
  }

  @override
  void dispose() {
    for (final c in [en, uz, ipa, ex]) {
      c.dispose();
    }
    enFocus.dispose();
    uzFocus.dispose();
    super.dispose();
  }

  void submit({bool more = false}) {
    final s = AppScope.read(context);
    final e = en.text.trim(), u = uz.text.trim();
    if (e.isEmpty || u.isEmpty) {
      setState(() => error = 'Inglizchasi va tarjimasini yozing');
      return;
    }
    var p = ipa.text.trim();
    if (p.isNotEmpty && !p.startsWith('/')) p = '/$p/';
    final w = Word(e, u, p, ex.text.trim());
    if (editing) {
      s.editMyWord(widget.editIndex!, w);
      Navigator.pop(context);
      toast(context, 'Saqlandi');
      return;
    }
    if (s.hasMyWord(e)) {
      setState(() => error = '"$e" allaqachon bor');
      return;
    }
    final unit = s.addMyWord(w);
    toast(context, "Mening so'zlarimga qo'shildi · Unit $unit");
    if (more) {
      for (final c in [en, uz, ipa, ex]) {
        c.clear();
      }
      setState(() => error = null);
      enFocus.requestFocus();
    } else {
      Navigator.pop(context);
    }
  }

  Widget field(String label, TextEditingController c, {String? hint, FocusNode? focus, bool small = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.mut)),
      const SizedBox(height: 6),
      TextField(
        controller: c,
        focusNode: focus,
        autocorrect: false,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: small ? 15 : 18),
        decoration: InputDecoration(hintText: hint),
        textInputAction: TextInputAction.next,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final nextUnit = (s.myWords.length ~/ 20) + 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            BookBadge(bookById(myBookId), size: 24),
            const SizedBox(width: 10),
            Text(editing ? "So'zni tahrirlash" : "Yangi so'z", style: display(18)),
          ]),
          const SizedBox(height: 14),
          field('Inglizcha *', en, hint: 'masalan: resilient', focus: enFocus),
          const SizedBox(height: 10),
          field('Tarjimasi *', uz, hint: 'masalan: chidamli, bardoshli', focus: uzFocus),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: field('Talaffuzi', ipa, hint: '/rɪˈzɪliənt/', small: true)),
            const SizedBox(width: 10),
            Expanded(child: field('Misol gap', ex, hint: 'ixtiyoriy', small: true)),
          ]),
          const SizedBox(height: 10),
          Text(
            '${editing ? '' : '"Mening so\'zlarim" kitobining Unit $nextUnit iga saqlanadi (har unitda 20 ta so\'z). '}'
            "Talaffuzni bilmasangiz bo'sh qoldiring: karta bosilganda baribir o'qib beradi.",
            style: const TextStyle(color: C.mut, fontSize: 12),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: C.bad, fontWeight: FontWeight.w800)),
          ],
          const SizedBox(height: 12),
          Btn(editing ? 'Saqlash' : "Qo'shish", onTap: submit),
          if (!editing) ...[
            const SizedBox(height: 10),
            Btn("Qo'shish va yana bittasi", kind: BtnKind.ghost, onTap: () => submit(more: true)),
          ],
        ]),
      ),
    );
  }
}
