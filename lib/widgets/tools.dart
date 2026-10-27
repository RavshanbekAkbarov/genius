import 'package:flutter/material.dart';

import '../services/speech.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import 'common.dart';

/// A- / A+ : so'zlar harf o'lchami (unit, kartalar). Hamma joyda saqlanadi.
class FontButtons extends StatelessWidget {
  const FontButtons({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SquareBtn(
        tooltip: 'Harfni kichraytirish',
        onTap: s.fontScale <= AppState.fontMin ? null : () => s.bumpFont(-1),
        child: const Text('A-', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
      const SizedBox(width: 6),
      SquareBtn(
        tooltip: 'Harfni kattalashtirish',
        onTap: s.fontScale >= AppState.fontMax ? null : () => s.bumpFont(1),
        child: const Text('A+', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    ]);
  }
}

/// 🔊 ovoz tanlash tugmasi.
class VoiceButton extends StatelessWidget {
  final bool light;
  const VoiceButton({super.key, this.light = false});
  @override
  Widget build(BuildContext context) => SquareBtn(
        tooltip: 'Ovozni tanlash',
        color: light ? Colors.black26 : null,
        onTap: () => showVoiceSheet(context),
        child: Icon(Icons.record_voice_over_rounded, size: 21, color: light ? Colors.white : C.fg),
      );
}

Future<void> showVoiceSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      backgroundColor: C.sf,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _VoiceSheet(),
    );

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();
  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  List<VoiceOption>? voices;

  @override
  void initState() {
    super.initState();
    Speech.voices().then((v) {
      if (mounted) setState(() => voices = v);
    });
  }

  Future<void> pick(VoiceOption v) async {
    final s = AppScope.read(context);
    s.setVoice(v.name, v.locale);
    await Speech.useVoice(v.name, v.locale);
    await Speech.speak('Hello! I will help you learn new words.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = voices;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Ovozni tanlang', style: display(18)),
          const SizedBox(height: 4),
          const Text("Bosib eshiting. Tanlagan ovozingiz hamma joyda shu holicha qoladi.",
              style: TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 12),
          if (list == null)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
          else if (list.isEmpty)
            const EmptyBox(
                "Telefonda inglizcha ovoz topilmadi. Sozlamalar → Til → Matnni nutqqa aylantirish bo'limidan Google ovozini o'rnating.")
          else
            for (final v in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: s.voiceName == v.name ? C.ac.withValues(alpha: .16) : C.sf2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: s.voiceName == v.name ? C.ac : Colors.transparent, width: 1.5)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: Icon(s.voiceName == v.name ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                        color: s.voiceName == v.name ? C.ac : C.mut),
                    title: Text(v.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => pick(v),
                  ),
                ),
              ),
          const SizedBox(height: 6),
          Btn('Tayyor', onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
