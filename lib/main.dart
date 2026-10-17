import 'package:flutter/material.dart';

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
      child: MaterialApp(
        title: 'Genius',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Birinchi ochilishda (server ulangan bo'lsa) kirish oynasi.
        home: cloudEnabled && !state.loginSeen && !Cloud.signedIn ? const LoginScreen(first: true) : const Shell(),
      ),
    );
  }
}
