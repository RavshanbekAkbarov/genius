import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'data/words.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'services/ads.dart';
import 'services/cloud.dart';
import 'services/net.dart';
import 'services/reminders.dart';
import 'services/speech.dart';
import 'services/word_widget.dart';
import 'state/app_state.dart';
import 'state/scope.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WordBank.load();
  final state = AppState();
  await state.load();
  Net.start();
  await Cloud.init(state);
  await Ads.init();
  await Reminders.init();
  Reminders.schedule(state);
  Reminders.watch(state);
  Speech.useVoice(state.voiceName, state.voiceLocale);
  WordWidget.update(state);
  runApp(GeniusApp(state: state));
}

class GeniusApp extends StatelessWidget {
  final AppState state;
  const GeniusApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      // Mavzu (qorong'i/yorug') o'zgarsa butun ilova yangi ranglar bilan qayta quriladi.
      child: ThemeSwitcher(
        state: state,
        builder: (light) {
          C.light = light;
          SystemChrome.setSystemUIOverlayStyle(light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light);
          return MaterialApp(
            key: ValueKey(light),
            title: 'Genius',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            // Telefonda juda katta shrift yoqilgan bo'lsa ham ekranlar buzilmasin: 1.3 barobargacha.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: .9, maxScaleFactor: 1.3)),
                child: child!,
              );
            },
            // Birinchi ochilishda (server ulangan bo'lsa) kirish oynasi.
            home: cloudEnabled && !state.loginSeen && !Cloud.signedIn ? const LoginScreen(first: true) : const Shell(),
          );
        },
      ),
    );
  }
}

/// Faqat [AppState.lightMode] o'zgarganda qayta quradi.
class ThemeSwitcher extends StatefulWidget {
  final AppState state;
  final Widget Function(bool light) builder;
  const ThemeSwitcher({super.key, required this.state, required this.builder});
  @override
  State<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher> {
  late bool light = widget.state.lightMode;

  void _on() {
    if (widget.state.lightMode != light) setState(() => light = widget.state.lightMode);
  }

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_on);
  }

  @override
  void dispose() {
    widget.state.removeListener(_on);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(light);
}
