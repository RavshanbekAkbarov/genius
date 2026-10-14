import 'package:flutter/material.dart';

import 'data/words.dart';
import 'screens/shell.dart';
import 'services/ads.dart';
import 'services/reminders.dart';
import 'state/app_state.dart';
import 'state/scope.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WordBank.load();
  final state = AppState();
  await state.load();
  await Ads.init();
  await Reminders.init();
  Reminders.schedule(state);
  Reminders.watch(state);
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
        home: const Shell(),
      ),
    );
  }
}
