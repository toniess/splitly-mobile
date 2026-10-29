import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitly/l10n/app_localizations.dart';
import 'package:splitly/main.dart';
import 'package:splitly/screens/auth_screen.dart';
import 'package:splitly/session.dart';

/// Сессия может кончиться, когда пользователь глубоко в стеке экранов:
/// refresh-токен отозван, а он смотрит группу. Приложение должно вернуть
/// его на вход, а не упасть на открытом экране.
void main() {
  testWidgets('выход из сессии на экране группы возвращает на вход', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final session = Session();
    await tester.pumpWidget(SplitlyApp(session: session));
    session.startDemo(lookupAppLocalizations(const Locale('ru')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поездка в Самарканд'));
    await tester.pumpAndSettle();
    expect(find.text('Траты'), findsOneWidget);

    session.logout();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Траты'), findsNothing);
  });
}
