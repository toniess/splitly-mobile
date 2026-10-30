import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splitly/api/http_api.dart';
import 'package:splitly/api/models.dart';
import 'package:splitly/l10n/app_localizations.dart';
import 'package:splitly/main.dart';
import 'package:splitly/session.dart';

/// Сквозной сценарий двумя пользователями через настоящий бэкенд: регистрация,
/// группа, вступление по коду, трата, балансы, «Я отдал».
///
/// В CI идёт против бэкенда, поднятого из .github/e2e/docker-compose.yml. Можно и против
/// прода (адрес по умолчанию), но тогда в боевой базе останутся пользователи
/// splitly-smoke-*@example.com, а удалить их можно только вручную:
///   flutter test integration_test/smoke_test.dart -d <устройство> [--dart-define=API_BASE=...]
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('вход, группа, трата, балансы, расчёт двумя пользователями', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final l = lookupAppLocalizations(const Locale('ru'));

    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'\D'), '').substring(0, 14);
    final anna = (email: 'splitly-smoke-a-$stamp@example.com', name: 'Анна smoke');
    final boris = (email: 'splitly-smoke-b-$stamp@example.com', name: 'Борис smoke');
    const password = 'SmokeTest-2026';
    debugPrint('SMOKE users: ${anna.email}, ${boris.email}');

    /// Ждём появления виджета: сеть настоящая, pumpAndSettle её не дожидается.
    Future<void> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 40)}) async {
      final end = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 250));
        if (finder.evaluate().isNotEmpty) return;
      }
      final onScreen = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText())
          .whereType<String>()
          .join(' | ');
      throw TestFailure('Не дождались: $finder\nНа экране: $onScreen');
    }

    /// «Назад» с верхнего экрана — после того как переходы доехали.
    Future<void> goBack() async {
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
    }

    Future<void> tapAndWait(Finder tap, Finder expected) async {
      await tester.pumpAndSettle();
      await tester.tap(tap);
      await waitFor(expected);
    }

    Future<void> signIn(String email) async {
      await tester.enterText(find.widgetWithText(TextFormField, l.authEmail), email);
      await tester.enterText(find.widgetWithText(TextFormField, l.authPassword), password);
      await tapAndWait(find.widgetWithText(FilledButton, l.authSignIn), find.text(l.groupsTitle));
    }

    Future<void> signOut() async {
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();
      await tapAndWait(find.text(l.groupsLogout), find.widgetWithText(FilledButton, l.authSignIn));
    }

    // ---------- Анна: регистрация через интерфейс ----------
    final session = Session()..restore();
    await tester.pumpWidget(SplitlyApp(session: session));
    await waitFor(find.text(l.authToSignUp));

    await tester.tap(find.text(l.authToSignUp));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, l.authName), anna.name);
    await tester.enterText(find.widgetWithText(TextFormField, l.authEmail), anna.email);
    await tester.enterText(find.widgetWithText(TextFormField, l.authPassword), password);
    await tapAndWait(find.widgetWithText(FilledButton, l.authSignUp), find.text(l.groupsEmpty));

    // ---------- группа ----------
    await tester.tap(find.widgetWithText(FloatingActionButton, l.groupsNew));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, l.groupName), 'Smoke $stamp');
    await tapAndWait(find.widgetWithText(FilledButton, l.groupCreate), find.text(l.tabExpenses));

    final groupTile = find.widgetWithText(ListTile, 'Smoke $stamp');
    final codeFinder = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.style?.fontFamily == 'monospace' &&
          RegExp(r'^[A-Z1-9]{4,12}$').hasMatch(w.data ?? ''),
    );
    await waitFor(codeFinder);
    final inviteCode = (tester.widget<Text>(codeFinder)).data!;
    debugPrint('SMOKE invite code: $inviteCode');

    // ---------- Борис вступает по коду (через API клиента, не через UI) ----------
    final borisApi = HttpSplitlyApi(tokens: _MemoryTokens());
    await tester.runAsync(() async {
      await borisApi.register(boris.email, password, boris.name);
      await borisApi.login(boris.email, password);
      await borisApi.joinGroup(inviteCode);
    });

    // Экран группы загрузил участников до вступления Бориса: свайп вниз обязан подтянуть его
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await waitFor(find.textContaining(l.groupMembers(2)));

    // ---------- трата 300 поровну, платила Анна ----------
    await tester.tap(find.widgetWithText(FloatingActionButton, l.expensesAdd));
    await tester.pumpAndSettle();
    expect(find.text(boris.name), findsOneWidget, reason: 'Борис есть среди участников траты');
    await tester.enterText(find.widgetWithText(TextFormField, l.formWhat), 'Ужин');
    await tester.enterText(find.widgetWithText(TextFormField, l.formAmount), '300');
    final expenseTile = find.widgetWithText(ListTile, 'Ужин');
    await tapAndWait(find.widgetWithText(FilledButton, l.save), expenseTile);

    await tapAndWait(expenseTile, find.text('150.00'));
    expect(find.text('150.00'), findsNWidgets(2), reason: 'по 150.00 на каждого');
    await goBack();

    await tapAndWait(find.text(l.tabBalances), find.text('+150.00'));
    expect(find.text('-150.00'), findsOneWidget);

    await tapAndWait(find.text(l.tabSettle), find.textContaining('→  ${l.settleToYou}', findRichText: true));
    expect(find.text(l.settlePaid), findsNothing, reason: 'Анна получает — кнопки у неё нет');

    // ---------- Борис входит через интерфейс и отдаёт долг ----------
    await goBack();
    await signOut();
    await signIn(boris.email);

    await waitFor(groupTile);
    await tapAndWait(groupTile, find.text(l.tabSettle));
    await tapAndWait(find.text(l.tabSettle), find.text(l.settlePaid));
    await tester.pumpAndSettle(); // вкладка ещё доезжает — иначе нажатие уйдёт мимо кнопки
    await tester.tap(find.text(l.settlePaid));
    await tester.pumpAndSettle();
    await tapAndWait(find.text(l.settleConfirmAction), find.text(l.settleEmpty));

    await tapAndWait(find.text(l.tabBalances), find.text('0.00'));
    await tester.pumpAndSettle();
    expect(find.text('0.00'), findsNWidgets(2), reason: 'после расчёта оба сальдо нулевые');

    await goBack();
    await signOut();
  });
}

class _MemoryTokens implements TokenStore {
  String? _access;
  String? _refresh;

  @override
  Future<String?> get access async => _access;

  @override
  Future<String?> get refresh async => _refresh;

  @override
  Future<void> save(TokenPair pair) async {
    _access = pair.accessToken;
    _refresh = pair.refreshToken;
  }

  @override
  Future<void> clear() async => _access = _refresh = null;
}
