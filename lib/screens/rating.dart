import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../services/cloud.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'login.dart';
import 'shell.dart';

/// Reyting: "Mening guruhim" va "Umumiy", har birida bugun / hafta / oy.
class RatingTab extends StatefulWidget {
  const RatingTab({super.key});
  @override
  State<RatingTab> createState() => _RatingTabState();
}

class _RatingTabState extends State<RatingTab> {
  bool group = true;
  int per = 1;
  Future<List<LbRow>>? rows;
  String? key;

  static const periods = ['day', 'week', 'month'];

  void load() {
    key = '$group|$per|${Cloud.signedIn}';
    rows = Cloud.signedIn ? Cloud.leaderboard(group ? 'group' : 'all', periods[per]) : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (key != '$group|$per|${Cloud.signedIn}') load();
    Widget seg(List<String> labels, int sel, void Function(int) onTap) => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            for (final (i, l) in labels.indexed)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => onTap(i)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                        color: sel == i ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: Text(l,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13, color: sel == i ? C.onAc : Colors.white)),
                  ),
                ),
              ),
          ]),
        );
    final body = <Widget>[];
    if (!Cloud.enabled) {
      final sample = [
        for (final p in samplePeople) LbRow(0, p.$1, '🙂', false, p.$2[per], false),
        LbRow(0, s.displayName, s.avatar, s.isPremium, s.myScore(per == 0 ? 0 : per == 1 ? 1 : 2), true),
      ]..sort((a, b) => b.score.compareTo(a.score));
      body.addAll(_list([for (final (i, r) in sample.indexed) LbRow(i + 1, r.nickname, r.avatar, r.premium, r.score, r.me)]));
      body.add(const Text('Namuna. Server ulangach haqiqiy reyting chiqadi.',
          textAlign: TextAlign.center, style: TextStyle(color: C.mut, fontSize: 12)));
    } else if (!Cloud.signedIn) {
      body.add(AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Reytingda qatnashish uchun hisobga kiring',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text("Hozir bu hafta: ${s.myScore(1)} so'z. Google yoki Telegram bilan bitta bosishda kirasiz.",
              style: const TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 12),
          Btn('Kirish', onTap: () => push(context, const LoginScreen())),
        ]),
      ));
    } else if (group && s.groupId == null) {
      body.add(AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Guruhingizni tanlang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          const Text("Guruhdoshlaringiz orasida nechanchi o'rindaligingizni ko'rasiz. Guruh bir marta tanlanadi.",
              style: TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 12),
          Btn('Guruhni tanlash', onTap: () async {
            await showGroupPicker(context);
            if (mounted) setState(load);
          }),
        ]),
      ));
    } else {
      body.add(FutureBuilder<List<LbRow>>(
        future: rows,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Column(children: [
              const EmptyBox("Reyting yuklanmadi. Internetni tekshiring."),
              TextButton(onPressed: () => setState(load), child: const Text('Qayta urinish')),
            ]);
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) return const EmptyBox("Hali hech kim so'z yodlamadi. Birinchi bo'ling!");
          return Column(children: _list(list));
        },
      ));
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(load);
        await rows;
      },
      child: ListView(padding: EdgeInsets.zero, children: [
        TabHeader(
          title: 'Reyting',
          subtitle: group ? (s.groupName ?? 'Mening guruhim') : "Hamma o'quvchilar",
          bottom: Column(children: [
            seg(['Mening guruhim', 'Umumiy'], group ? 0 : 1, (i) => group = i == 0),
            const SizedBox(height: 8),
            seg(['Bugun', 'Hafta', 'Oy'], per, (i) => per = i),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), child: Column(children: body)),
      ]),
    );
  }

  List<Widget> _list(List<LbRow> rows) {
    final medal = [const Color(0xFFFFD34D), const Color(0xFFCFD6E0), const Color(0xFFE2A36B)];
    final out = <Widget>[];
    for (final (i, r) in rows.indexed) {
      final top = r.rank <= 3;
      if (i > 0 && rows[i - 1].rank + 1 < r.rank) {
        out.add(const Padding(
            padding: EdgeInsets.only(bottom: 8), child: Text('···', style: TextStyle(color: C.mut, fontSize: 18))));
      }
      final ahead = r.me && i > 0 ? rows[i - 1] : null;
      out.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: C.sf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: r.me ? C.ac : C.ln, width: r.me ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: top ? medal[r.rank - 1] : C.sf2),
            alignment: Alignment.center,
            child: Text('${r.rank}',
                style: TextStyle(fontWeight: FontWeight.w800, color: top ? const Color(0xFF1A1200) : C.mut)),
          ),
          const SizedBox(width: 10),
          Text(r.avatar, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(r.me ? '${r.nickname} (siz)' : r.nickname,
                      overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (r.premium) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 18),
                ],
              ]),
              if (ahead != null)
                Text("Keyingi o'ringa ${ahead.score - r.score + 1} so'z qoldi",
                    style: const TextStyle(color: C.mut, fontSize: 12)),
            ]),
          ),
          Text("${r.score} so'z", style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ));
    }
    return out;
  }
}

/// Guruhni bir marta tanlash.
Future<void> showGroupPicker(BuildContext context) async {
  List<Group> list;
  try {
    list = await Cloud.groups();
  } catch (_) {
    if (context.mounted) toast(context, 'Guruhlar yuklanmadi, internetni tekshiring');
    return;
  }
  if (!context.mounted) return;
  if (list.isEmpty) {
    toast(context, "Guruhlar hali qo'shilmagan. O'qituvchingizdan so'rang");
    return;
  }
  final g = await showModalBottomSheet<Group>(
    context: context,
    backgroundColor: C.sf,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .7),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), children: [
          Text('Guruhingizni tanlang', style: display(18)),
          const SizedBox(height: 4),
          const Text("Diqqat: guruh bir marta tanlanadi. Keyin faqat o'qituvchi o'zgartira oladi.",
              style: TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 12),
          for (final g in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: C.sf2,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: const Icon(Icons.groups_rounded, color: C.ac),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () => Navigator.pop(ctx, g),
                ),
              ),
            ),
        ]),
      ),
    ),
  );
  if (g == null || !context.mounted) return;
  final err = await Cloud.setGroup(g);
  if (context.mounted) toast(context, err ?? '${g.name} guruhi tanlandi');
}

/// Reyting bo'limini ochish (masalan, eslatmadan).
void goRating(BuildContext context) => ShellScope.of(context).goTab(2);
