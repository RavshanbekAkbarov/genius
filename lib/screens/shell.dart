import 'package:flutter/material.dart';

import '../services/ads.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/book_drawer.dart';
import 'books.dart';
import 'home.dart';
import 'profile.dart';
import 'shop.dart';

/// Asosiy oyna: 4 ta bo'lim, ☰ menyusi va eng pastda reklama banneri.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int tab = 0;

  void goTab(int i) => setState(() => tab = i);
  void openDrawer() => scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ShellScope(
      state: this,
      child: Scaffold(
        key: scaffoldKey,
        drawer: BookDrawer(onPicked: () => goTab(0)),
        body: IndexedStack(index: tab, children: const [
          HomeTab(),
          BooksTab(),
          ShopTab(),
          ProfileTab(),
        ]),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: C.sf,
              indicatorColor: C.ac.withValues(alpha: .18),
              labelTextStyle: WidgetStateProperty.resolveWith((st) => TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: st.contains(WidgetState.selected) ? C.ac : C.mut)),
              iconTheme: WidgetStateProperty.resolveWith(
                  (st) => IconThemeData(color: st.contains(WidgetState.selected) ? C.ac : C.mut)),
            ),
            child: NavigationBar(
              height: 62,
              selectedIndex: tab,
              onDestinationSelected: goTab,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Asosiy'),
                NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Kitoblar'),
                NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: "Do'kon"),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
              ],
            ),
          ),
          // Banner tugmalar qatorining tagida; Premium'da ko'rinmaydi.
          if (!s.isPremium) const SafeArea(top: false, child: AdBanner()),
        ]),
      ),
    );
  }
}

class ShellScope extends InheritedWidget {
  final ShellState state;
  const ShellScope({super.key, required this.state, required super.child});
  static ShellState of(BuildContext context) => context.getInheritedWidgetOfExactType<ShellScope>()!.state;
  @override
  bool updateShouldNotify(ShellScope old) => false;
}

class BurgerButton extends StatelessWidget {
  const BurgerButton({super.key});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ShellScope.of(context).openDrawer(),
          child: const SizedBox(
              width: 44, height: 44, child: Icon(Icons.menu_rounded, color: Colors.white, semanticLabel: 'Menyu')),
        ),
      );
}

/// Bo'limlar uchun ko'k sarlavha (Kitoblar, Do'kon, Profil).
class TabHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? bottom;
  const TabHeader({super.key, required this.title, required this.subtitle, this.bottom});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: C.grad,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 16),
        child: Column(children: [
          Row(children: [
            const BurgerButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: display(22, color: Colors.white)),
                Text(subtitle.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.white70)),
              ]),
            ),
          ]),
          if (bottom != null) ...[const SizedBox(height: 12), bottom!],
        ]),
      );
}
