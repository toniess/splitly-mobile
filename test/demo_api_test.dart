import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitly/api/demo_api.dart';
import 'package:splitly/api/models.dart';
import 'package:splitly/api/splitly_api.dart';
import 'package:splitly/l10n/app_localizations.dart';

// Песочница повторяет серверные расчёты, поэтому проверяем её на те же
// инварианты, что и бэкенд (раздел 10 ТЗ).

const _a = '00000000-0000-0000-0000-00000000000a';
const _b = '00000000-0000-0000-0000-00000000000b';
const _c = '00000000-0000-0000-0000-00000000000c';

int cents(String v) {
  final negative = v.startsWith('-');
  final parts = v.replaceFirst('-', '').split('.');
  final result = int.parse(parts[0]) * 100 + int.parse(parts[1]);
  return negative ? -result : result;
}

NewExpense expense(String amount, SplitType type, List<Participant> participants) => NewExpense(
  description: 'тест',
  amount: amount,
  payerId: _a,
  spentAt: DateTime.utc(2026, 10, 1),
  splitType: type,
  participants: participants,
);

void main() {
  late DemoSplitlyApi api;

  setUp(() => api = DemoSplitlyApi(lookupAppLocalizations(const Locale('ru'))));

  test('100.00 на троих: 33.34 + 33.33 + 33.33', () async {
    final e = await api.createExpense(
      'g',
      expense('100.00', SplitType.equal, const [
        Participant(_a, null),
        Participant(_b, null),
        Participant(_c, null),
      ]),
      idempotencyKey: 'k1',
    );
    expect(e.shares.map((s) => s.amount), ['33.34', '33.33', '33.33']);
  });

  test('0.01 на двоих: одному копейка, другому ноль', () async {
    final e = await api.createExpense(
      'g',
      expense('0.01', SplitType.equal, const [Participant(_a, null), Participant(_b, null)]),
      idempotencyKey: 'k1',
    );
    expect(e.shares.map((s) => s.amount), ['0.01', '0.00']);
  });

  test('EXACT с суммой долей не равной сумме траты — отказ 422', () async {
    await expectLater(
      api.createExpense(
        'g',
        expense('100.00', SplitType.exact, const [Participant(_a, '50.00'), Participant(_b, '40.00')]),
        idempotencyKey: 'k1',
      ),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', 422)),
    );
  });

  test('SHARES делит пропорционально и не теряет копейки', () async {
    final e = await api.createExpense(
      'g',
      expense('100.00', SplitType.shares, const [Participant(_a, '1'), Participant(_b, '2')]),
      idempotencyKey: 'k1',
    );
    expect(e.shares.map((s) => cents(s.amount)).reduce((a, b) => a + b), 10000);
  });

  test('SHARES: участник с весом 0 не получает копейку остатка', () async {
    final e = await api.createExpense(
      'g',
      expense('100.00', SplitType.shares, const [
        Participant(_a, '0'),
        Participant(_b, '1'),
        Participant(_c, '1'),
      ]),
      idempotencyKey: 'k1',
    );
    expect(e.shares.map((s) => s.amount), ['0.00', '50.00', '50.00']);
  });

  test('SHARES 0:1:2 — копейка остатка первому платящему, а не участнику с весом 0', () async {
    final e = await api.createExpense(
      'g',
      expense('100.00', SplitType.shares, const [
        Participant(_a, '0'),
        Participant(_b, '1'),
        Participant(_c, '2'),
      ]),
      idempotencyKey: 'k2',
    );
    expect(e.shares.map((s) => s.amount), ['0.00', '33.34', '66.66']);
  });

  test('повторный Idempotency-Key не создаёт вторую трату', () async {
    final before = (await api.feed('g')).items.length;
    final body = expense('10.00', SplitType.equal, const [Participant(_a, null)]);
    final first = await api.createExpense('g', body, idempotencyKey: 'same');
    final second = await api.createExpense('g', body, idempotencyKey: 'same');
    expect(second.id, first.id);
    expect((await api.feed('g')).items.length, before + 1);
  });

  test('сумма сальдо равна нулю, а план обнуляет все сальдо', () async {
    final balances = await api.balances('g');
    expect(balances.map((b) => cents(b.balance)).reduce((a, b) => a + b), 0);
    expect(balances.any((b) => cents(b.balance) != 0), isTrue);

    var i = 0;
    for (final t in await api.plan('g')) {
      await api.settle('g', t, idempotencyKey: 'settle-${i++}');
    }
    expect((await api.balances('g')).every((b) => cents(b.balance) == 0), isTrue);
    expect(await api.plan('g'), isEmpty);
  });
}
