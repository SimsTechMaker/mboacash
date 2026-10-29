import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the black-screen bug: a second Navigator in MaterialApp.builder
/// (the lock screen) must not share the app's HeroController, otherwise every
/// push after it is removed throws in HeroController.didChangeTop.
void main() {
  testWidgets('pushing a page after an overlay navigator is removed works', (tester) async {
    final locked = ValueNotifier(true);
    final appNav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNav,
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: locked,
          builder: (_, isLocked, _) => Stack(
            children: [
              Offstage(offstage: isLocked, child: child),
              if (isLocked)
                HeroControllerScope.none(
                  child: Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const Text('verrouillé'))),
                ),
            ],
          ),
        ),
        home: const Text('accueil'),
      ),
    );
    locked.value = false;
    await tester.pumpAndSettle();
    appNav.currentState!.push(MaterialPageRoute(builder: (_) => const Text('page suivante')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('page suivante'), findsOneWidget);
  });
}
