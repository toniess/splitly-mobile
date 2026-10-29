import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitly/l10n/app_localizations.dart';
import 'package:splitly/main.dart';
import 'package:splitly/session.dart';

void main() {
  group('выбор языка', () {
    const supported = AppLocalizations.supportedLocales;

    test('русский и английский — как в системе', () {
      expect(resolveLocale(const [Locale('ru', 'RU')], supported), const Locale('ru'));
      expect(resolveLocale(const [Locale('en', 'GB')], supported), const Locale('en'));
    });

    test('берётся первый известный язык из списка системы', () {
      expect(resolveLocale(const [Locale('de'), Locale('ru')], supported), const Locale('ru'));
    });

    test('без известных языков: СНГ — русский, остальные — английский', () {
      expect(resolveLocale(const [Locale('uz')], supported), const Locale('ru'));
      expect(resolveLocale(const [Locale('kk')], supported), const Locale('ru'));
      expect(resolveLocale(const [Locale('de')], supported), const Locale('en'));
      expect(resolveLocale(null, supported), const Locale('en'));
    });
  });

  test('русские множественные числа', () {
    final l = lookupAppLocalizations(const Locale('ru'));
    expect(l.groupMembers(1), '1 участник');
    expect(l.groupMembers(3), '3 участника');
    expect(l.groupMembers(5), '5 участников');
    expect(l.groupMembers(21), '21 участник');
    expect(l.groupMembers(11), '11 участников');
  });

  testWidgets('английский интерфейс и демо целиком на английском', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final session = Session();
    await tester.pumpWidget(SplitlyApp(session: session));
    session.startDemo(lookupAppLocalizations(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Groups'), findsOneWidget);
    await tester.tap(find.text('Trip to Samarkand'));
    await tester.pumpAndSettle();

    expect(find.text('3 members · UZS'), findsOneWidget);
    expect(find.text('Hotel, two nights'), findsOneWidget);
    expect(find.textContaining('Oct 2, 2026'), findsOneWidget);
    await tester.tap(find.text('Settle up'));
    await tester.pumpAndSettle();
    expect(find.textContaining('→  you'), findsWidgets);
  });
}
