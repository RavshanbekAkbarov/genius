import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Holatni butun ilovaga uzatadi; `AppScope.of(context)` chaqirgan widget holat o'zgarganda qayta chiziladi.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Qayta chizishga obuna bo'lmasdan o'qish (tugma bosilganda).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
