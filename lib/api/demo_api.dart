// Демо-режим: тот же интерфейс, что у настоящего клиента, но всё живёт
// в памяти процесса. Вышел из демо — начал заново.
//
// Почему не демо-аккаунт на сервере: Neon на бесплатном тарифе засыпает,
// и первый запрос ждал бы пробуждения базы около десяти секунд. Плюс не нужно
// держать пароль демо-пользователя в публичном репозитории.
//
// Расчёты повторяют серверные (и веб-демо): деление в копейках, остаток по
// одной копейке участникам в порядке userId, жадный план переводов. Это
// осознанное дублирование ради автономности — настоящие деньги считает сервер.

import '../l10n/app_localizations.dart';
import 'models.dart';
import 'splitly_api.dart';

const _me = '00000000-0000-0000-0000-00000000000a';
const _maria = '00000000-0000-0000-0000-00000000000b';
const _igor = '00000000-0000-0000-0000-00000000000c';
const _groupId = '00000000-0000-0000-0000-0000000000f1';

// ---------- деньги ----------

/// Строка → копейки без double: "300.3" → 30030.
int _toCents(String value) {
  final text = value.trim().replaceAll(',', '.');
  final negative = text.startsWith('-');
  final parts = text.replaceFirst('-', '').split('.');
  final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]) ?? 0;
  final fraction = parts.length > 1 ? '${parts[1]}00'.substring(0, 2) : '00';
  final cents = whole * 100 + (int.tryParse(fraction) ?? 0);
  return negative ? -cents : cents;
}

String _fromCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}

/// Раздаёт [remainder] копеек по одной в порядке userId.
void _spreadRemainder(Map<String, int> result, int remainder) {
  final ordered = result.keys.toList()..sort();
  for (var i = 0; remainder > 0; i = (i + 1) % ordered.length, remainder--) {
    result[ordered[i]] = result[ordered[i]]! + 1;
  }
}

Map<String, int> _split(AppLocalizations l, int amountCents, SplitType type, List<Participant> participants) {
  switch (type) {
    case SplitType.equal:
      final result = {for (final p in participants) p.userId: amountCents ~/ participants.length};
      _spreadRemainder(result, amountCents % participants.length);
      return result;

    case SplitType.exact:
      return {for (final p in participants) p.userId: _toCents(p.value ?? '0')};

    case SplitType.shares:
      // Веса — целые доли; дробные бэкенд тоже отклонил бы.
      final weights = [for (final p in participants) int.tryParse(p.value ?? '1') ?? 1];
      final total = weights.fold(0, (a, b) => a + b);
      if (weights.any((w) => w < 0) || total <= 0) {
        throw ApiError(status: 422, title: l.demoSharesPositive);
      }
      final result = <String, int>{};
      var given = 0;
      for (var i = 0; i < participants.length; i++) {
        final share = amountCents * weights[i] ~/ total;
        result[participants[i].userId] = share;
        given += share;
      }
      // Как на сервере: вес 0 — «не платит», копейка остатка ему не положена
      final paying = {
        for (var i = 0; i < participants.length; i++)
          if (weights[i] > 0) participants[i].userId: result[participants[i].userId]!,
      };
      _spreadRemainder(paying, amountCents - given);
      result.addAll(paying);
      return result;
  }
}

class _StoredExpense {
  final Expense expense;
  final int amountCents;
  final Map<String, int> sharesCents;

  _StoredExpense(this.expense, this.amountCents, this.sharesCents);
}

class DemoSplitlyApi implements SplitlyApi {
  /// Песочница говорит на языке интерфейса: и названия в сиде, и ошибки.
  final AppLocalizations _l;

  // Имя, а не «Вы»: интерфейс сам подпишет «(вы)» и заменит на «Вы» где нужно.
  late final _user = User(id: _me, email: 'demo@splitly.dev', displayName: _l.demoMe);

  late final _members = [
    GroupMember(userId: _me, displayName: _l.demoMe, role: MemberRole.owner),
    GroupMember(userId: _maria, displayName: _l.demoMaria, role: MemberRole.member),
    GroupMember(userId: _igor, displayName: _l.demoIgor, role: MemberRole.member),
  ];

  late final _group = Group(id: _groupId, name: _l.demoGroup, currency: 'UZS', inviteCode: 'DEMO42');

  final _expenses = <_StoredExpense>[];
  final _settlements = <({String from, String to, int cents})>[];
  final _idempotent = <String, Object>{};
  var _counter = 0;

  DemoSplitlyApi(this._l) {
    _seed();
  }

  /// Заполняет песочницу так, чтобы сразу было что посмотреть.
  void _seed() {
    const all = [Participant(_me, null), Participant(_maria, null), Participant(_igor, null)];
    _add(
      NewExpense(
        description: _l.demoHotel,
        amount: '1200.00',
        payerId: _me,
        spentAt: DateTime.utc(2026, 10, 2, 12),
        splitType: SplitType.equal,
        participants: all,
      ),
    );
    _add(
      NewExpense(
        description: _l.demoDinner,
        amount: '450.00',
        payerId: _maria,
        spentAt: DateTime.utc(2026, 10, 3, 19, 30),
        splitType: SplitType.equal,
        participants: all,
      ),
    );
    // 100.00 на троих показывает раздачу остатка: 33.34 + 33.33 + 33.33
    _add(
      NewExpense(
        description: _l.demoTaxi,
        amount: '100.00',
        payerId: _me,
        spentAt: DateTime.utc(2026, 10, 3, 9),
        splitType: SplitType.equal,
        participants: all,
      ),
    );
  }

  String _nameOf(String id) =>
      _members.where((m) => m.userId == id).map((m) => m.displayName).firstOrNull ?? '—';

  Expense _add(NewExpense body) {
    if (body.participants.isEmpty) {
      throw ApiError(status: 422, title: _l.demoNoParticipants);
    }
    final amountCents = _toCents(body.amount);
    if (amountCents <= 0) {
      throw ApiError(status: 422, title: _l.demoAmountPositive);
    }
    final shares = _split(_l, amountCents, body.splitType, body.participants);
    if (shares.values.fold(0, (a, b) => a + b) != amountCents) {
      throw ApiError(status: 422, title: _l.demoSumMismatch);
    }

    final ids = shares.keys.toList()..sort();
    final expense = Expense(
      id: 'demo-${_counter++}',
      groupId: _groupId,
      payerId: body.payerId,
      amount: _fromCents(amountCents),
      currency: _group.currency,
      description: body.description,
      spentAt: body.spentAt,
      splitType: body.splitType,
      shares: [
        for (final id in ids) Share(userId: id, displayName: _nameOf(id), amount: _fromCents(shares[id]!)),
      ],
    );
    _expenses.insert(0, _StoredExpense(expense, amountCents, shares));
    _expenses.sort((a, b) => b.expense.spentAt.compareTo(a.expense.spentAt));
    return expense;
  }

  Map<String, int> _balanceCents() {
    final result = {for (final m in _members) m.userId: 0};
    for (final e in _expenses) {
      result[e.expense.payerId] = result[e.expense.payerId]! + e.amountCents;
      e.sharesCents.forEach((id, cents) => result[id] = result[id]! - cents);
    }
    for (final s in _settlements) {
      result[s.from] = result[s.from]! + s.cents;
      result[s.to] = result[s.to]! - s.cents;
    }
    return result;
  }

  /// Жадный план: крупнейший должник гасит крупнейшему кредитору.
  List<Transfer> _plan() {
    final balances = _balanceCents().entries;
    int byAmount(MapEntry<String, int> a, MapEntry<String, int> b) {
      final diff = b.value.abs() - a.value.abs();
      return diff != 0 ? diff : a.key.compareTo(b.key);
    }

    final debtors = balances.where((e) => e.value < 0).toList()..sort(byAmount);
    final creditors = balances.where((e) => e.value > 0).toList()..sort(byAmount);
    final left = [for (final d in debtors) -d.value];
    final need = [for (final c in creditors) c.value];

    final transfers = <Transfer>[];
    var i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final amount = left[i] < need[j] ? left[i] : need[j];
      if (amount > 0) {
        transfers.add(Transfer(from: debtors[i].key, to: creditors[j].key, amount: _fromCents(amount)));
        left[i] -= amount;
        need[j] -= amount;
      }
      if (left[i] == 0) i++;
      if (need[j] == 0) j++;
    }
    return transfers;
  }

  /// Небольшая задержка, чтобы индикаторы загрузки в демо выглядели как в жизни.
  Future<T> _wait<T>(T Function() value) => Future.delayed(const Duration(milliseconds: 150), value);

  @override
  Future<void> register(String email, String password, String displayName) => _wait(() {});

  @override
  Future<void> login(String email, String password) => _wait(() {});

  @override
  Future<void> logout() async {}

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<User> me() => _wait(() => _user);

  @override
  Future<List<GroupSummary>> groups() => _wait(() => [_group]);

  @override
  Future<Group> group(String id) => _wait(() => _group);

  @override
  Future<Group> createGroup(String name, String currency) =>
      _wait(() => throw ApiError(status: 403, title: _l.demoOneGroup));

  @override
  Future<void> joinGroup(String inviteCode) => _wait(() => throw ApiError(status: 404, title: _l.demoNoJoin));

  @override
  Future<List<GroupMember>> members(String groupId) => _wait(() => _members);

  @override
  Future<void> leaveGroup(String groupId) => _wait(() => throw ApiError(status: 403, title: _l.demoNoLeave));

  @override
  Future<ExpenseFeedPage> feed(String groupId, {String? cursor, int limit = 20}) => _wait(
    () => ExpenseFeedPage(
      items: [
        for (final e in _expenses)
          ExpenseSummary(
            id: e.expense.id,
            description: e.expense.description,
            amount: e.expense.amount,
            payerId: e.expense.payerId,
            spentAt: e.expense.spentAt,
          ),
      ],
    ),
  );

  @override
  Future<Expense> expense(String id) => _wait(() {
    final found = _expenses.where((e) => e.expense.id == id).firstOrNull;
    if (found == null) throw ApiError(status: 404, title: _l.demoNotFound);
    return found.expense;
  });

  @override
  Future<Expense> createExpense(String groupId, NewExpense body, {required String idempotencyKey}) =>
      _wait(() => _idempotent.putIfAbsent(idempotencyKey, () => _add(body)) as Expense);

  @override
  Future<void> deleteExpense(String id) => _wait(() => _expenses.removeWhere((e) => e.expense.id == id));

  @override
  Future<List<Balance>> balances(String groupId) => _wait(() {
    final cents = _balanceCents();
    return [
      for (final m in _members)
        Balance(userId: m.userId, displayName: m.displayName, balance: _fromCents(cents[m.userId]!)),
    ];
  });

  @override
  Future<List<Transfer>> plan(String groupId) => _wait(_plan);

  @override
  Future<void> settle(String groupId, Transfer transfer, {required String idempotencyKey}) => _wait(() {
    _idempotent.putIfAbsent(idempotencyKey, () {
      _settlements.add((from: transfer.from, to: transfer.to, cents: _toCents(transfer.amount)));
      return true;
    });
  });
}
