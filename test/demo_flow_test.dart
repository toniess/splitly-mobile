import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitly/l10n/app_localizations.dart';
import 'package:splitly/main.dart';
import 'package:splitly/session.dart';

/// Сквозной сценарий по экранам в демо-режиме: сервер не нужен.
void main() {
  testWidgets('демо: группа → трата → балансы → расчёт', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // restore() не вызываем: Keychain в тестах недоступен, начинаем с экрана входа.
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final session = Session();
    await tester.pumpWidget(SplitlyApp(session: session));
    // Заставка висит, пока сессия не проверена, — минуем её через демо.
    // Без await: время в тесте фейковое, задержка песочницы истечёт только при pump.
    session.startDemo(lookupAppLocalizations(const Locale('ru')));
    await tester.pumpAndSettle();

    expect(find.text('Поездка в Самарканд'), findsOneWidget);
    await tester.tap(find.text('Поездка в Самарканд'));
    await tester.pumpAndSettle();

    expect(find.text('Отель, две ночи'), findsOneWidget);

    // Новая трата: 90 поровну на троих
    await tester.tap(find.text('Трата'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'На что'), 'Дыня на базаре');
    await tester.enterText(find.widgetWithText(TextFormField, 'Сколько'), '90');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Дыня на базаре'), findsOneWidget);

    // Детали траты
    await tester.tap(find.text('Дыня на базаре'));
    await tester.pumpAndSettle();
    expect(find.text('30.00'), findsNWidgets(3));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Балансы'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Мария'), findsOneWidget);

    await tester.tap(find.text('Расчёт'));
    await tester.pumpAndSettle();
    // В сиде больше всех заплатили «Вы»: остальные переводят вам, кнопки «Я отдал» у вас нет.
    expect(find.textContaining('→  вам'), findsWidgets);
    expect(find.text('Я отдал'), findsNothing);
  });
}
