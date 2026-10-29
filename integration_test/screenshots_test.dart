import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splitly/l10n/app_localizations.dart';
import 'package:splitly/main.dart';
import 'package:splitly/session.dart';

/// Скриншоты для страницы в магазине. Снимаются с демо-данных, на обоих языках:
///   flutter drive --driver=test_driver/screenshots.dart \
///     --target=integration_test/screenshots_test.dart -d <симулятор>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final code in ['ru', 'en']) {
    testWidgets('скриншоты $code', (tester) async {
      final locale = Locale(code);
      final l = lookupAppLocalizations(locale);
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await binding.takeScreenshot('${code}_$name');
      }

      final session = Session();
      await tester.pumpWidget(SplitlyApp(session: session));
      // Android снимает экран только с картинки, а не с живой поверхности; переключить
      // можно один раз за тест.
      await binding.convertFlutterSurfaceToImage();
      await session.startDemo(l);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.demoGroup));
      await shot('1_expenses');

      await tester.tap(find.text(l.expensesAdd));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, l.formWhat),
        code == 'ru' ? 'Дыня на базаре' : 'Melon at the bazaar',
      );
      await tester.enterText(find.widgetWithText(TextFormField, l.formAmount), '90');
      FocusManager.instance.primaryFocus?.unfocus();
      await shot('2_new_expense');
      await tester.tap(find.text(l.save));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.tabBalances));
      await shot('3_balances');

      await tester.tap(find.text(l.tabSettle));
      await shot('4_settle');
    });
  }
}
