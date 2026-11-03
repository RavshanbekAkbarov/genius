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
          _NavBar(index: tab, onTap: goTab),
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
        color: C.sf2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => ShellScope.of(context).openDrawer(),
          child: const SizedBox(
              width: 44, height: 44, child: Icon(Icons.menu_rounded, color: C.fg, size: 22, semanticLabel: 'Menyu')),
        ),
      );
}

/// Bo'limlar sarlavhasi (Kitoblar, Do'kon, Profil): katta, toza sarlavha.
class TabHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? bottom;
  const TabHeader({super.key, required this.title, required this.subtitle, this.bottom});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: display(28)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.mut)),
              ]),
            ),
            const BurgerButton(),
          ]),
          if (bottom != null) ...[const SizedBox(height: 14), bottom!],
        ]),
      );
}

/// Pastki menyu: tanlangan bo'lim ikonkasi rangli "tabletka" ichida.
class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  static const items = [
    (Icons.home_outlined, Icons.home_rounded, 'Asosiy'),
    (Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Kitoblar'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, "Do'kon"),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: C.sf,
          border: Border(top: BorderSide(color: C.ln)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    child: InkResponse(
                      onTap: () => onTap(i),
                      radius: 40,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: i == index ? 56 : 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: i == index ? C.ac.withValues(alpha: .18) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(i == index ? items[i].$2 : items[i].$1,
                              size: 23, color: i == index ? C.ac : C.mut),
                        ),
                        const SizedBox(height: 4),
                        Text(items[i].$3,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                                color: i == index ? C.fg : C.mut)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
}
