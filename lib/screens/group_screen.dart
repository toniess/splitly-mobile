import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/models.dart';
import '../session.dart';
import '../ui/common.dart';
import '../ui/theme.dart';
import 'expense_form_screen.dart';
import 'expense_screen.dart';

/// Группа: шапка с кодом приглашения и три вкладки — траты, балансы, расчёт.
///
/// Данные экрана — два запроса (группа и участники). Ленту, балансы и план
/// каждая вкладка грузит сама, и только когда её открыли.
class GroupScreen extends StatefulWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  Group? _group;
  List<GroupMember> _members = const [];
  Object? _error;

  /// Растёт после любого изменения денег: вкладки с балансами и планом
  /// получают новый ключ и перечитывают данные.
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = SessionScope.read(context).api;
    setState(() => _error = null);
    try {
      final (group, members) = await (api.group(widget.groupId), api.members(widget.groupId)).wait;
      if (mounted) {
        setState(() {
          _group = group;
          _members = members;
        });
      }
    } on ParallelWaitError<(Group?, List<GroupMember>?), (AsyncError?, AsyncError?)> catch (e) {
      if (mounted) setState(() => _error = (e.errors.$1 ?? e.errors.$2)!.error);
    }
  }

  String _nameOf(String userId) {
    final me = SessionScope.read(context).me;
    if (userId == me?.id) return context.l10n.you;
    return _members.where((m) => m.userId == userId).firstOrNull?.displayName ?? '—';
  }

  void _changed() => setState(() => _revision++);

  Future<void> _copyInvite() async {
    final code = _group!.inviteCode;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.groupInviteCopied(code))));
    }
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.groupLeaveConfirm),
        content: Text(context.l10n.groupLeaveHint),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.groupLeaveAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await SessionScope.read(context).api.leaveGroup(widget.groupId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ErrorBox(_error),
                    OutlinedButton(onPressed: _load, child: Text(context.l10n.retry)),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    // Сессия могла кончиться, пока экран открыт: приложение уже снимает стек,
    // а этот кадр — последний. Падать на нём незачем.
    final meId = SessionScope.of(context).me?.id ?? '';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.name, overflow: TextOverflow.ellipsis),
              Text(
                '${context.l10n.groupMembers(_members.length)} · ${group.currency}',
                style: const TextStyle(fontSize: 12, color: Palette.muted, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _copyInvite,
              icon: const Icon(Icons.copy, size: 16),
              label: Text(group.inviteCode, style: const TextStyle(fontFamily: 'monospace')),
            ),
            PopupMenuButton<void>(
              itemBuilder: (_) => [PopupMenuItem(onTap: _leave, child: Text(context.l10n.groupLeave))],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.tabExpenses),
              Tab(text: context.l10n.tabBalances),
              Tab(text: context.l10n.tabSettle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ExpensesTab(
              groupId: widget.groupId,
              meId: meId,
              members: _members,
              nameOf: _nameOf,
              onChanged: _changed,
            ),
            _BalancesTab(key: ValueKey(('balances', _revision)), groupId: widget.groupId, meId: meId),
            _SettleTab(
              key: ValueKey(('settle', _revision)),
              groupId: widget.groupId,
              meId: meId,
              nameOf: _nameOf,
              onChanged: _changed,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- траты ----------

class _ExpensesTab extends StatefulWidget {
  final String groupId;
  final String meId;
  final List<GroupMember> members;
  final String Function(String userId) nameOf;
  final VoidCallback onChanged;

  const _ExpensesTab({
    required this.groupId,
    required this.meId,
    required this.members,
    required this.nameOf,
    required this.onChanged,
  });

  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> with AutomaticKeepAliveClientMixin {
  final _items = <ExpenseSummary>[];
  String? _cursor;
  bool _loading = false;
  bool _loaded = false;
  Object? _error;

  // Лента не должна перечитываться при каждом переключении вкладок.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  /// Номер текущей загрузки. Обновление ленты не ждёт подгрузки следующей
  /// страницы, а отменяет её: ответ устаревшего запроса просто выбрасывается.
  int _generation = 0;

  /// Курсорная пагинация: следующая страница начинается там, где кончилась
  /// предыдущая, и новые траты не сдвигают уже показанные.
  Future<void> _load({required bool reset}) async {
    if (!reset && (_loading || _cursor == null)) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await SessionScope.read(context).api.feed(widget.groupId, cursor: reset ? null : _cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _loaded = true;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            ExpenseFormScreen(groupId: widget.groupId, meId: widget.meId, members: widget.members),
      ),
    );
    if (created == true) {
      widget.onChanged();
      _load(reset: true);
    }
  }

  Future<void> _open(ExpenseSummary e) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseScreen(expenseId: e.id, nameOf: widget.nameOf),
      ),
    );
    if (deleted == true) {
      widget.onChanged();
      _load(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: widget.members.isEmpty ? null : _add,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.expensesAdd),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: NotificationListener<ScrollNotification>(
          // Подгружаем следующую страницу заранее, за экран до конца списка.
          onNotification: (n) {
            // После ошибки сами не повторяем — иначе каждая прокрутка шлёт запрос.
            if (_error == null && n.metrics.extentAfter < 600) _load(reset: false);
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: _items.length + 1,
            itemBuilder: (context, i) {
              if (i < _items.length) {
                final e = _items[i];
                return Card(
                  child: ListTile(
                    title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${widget.nameOf(e.payerId)} · ${formatDate(context, e.spentAt)}'),
                    trailing: Money(e.amount, style: const TextStyle(fontSize: 16)),
                    onTap: () => _open(e),
                  ),
                );
              }
              // Последний элемент — состояние ленты.
              if (_error != null) {
                return Column(
                  children: [
                    ErrorBox(_error),
                    OutlinedButton(
                      onPressed: () => _load(reset: _items.isEmpty),
                      child: Text(context.l10n.retry),
                    ),
                  ],
                );
              }
              if (_loading || !_loaded) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_items.isEmpty) return EmptyState(context.l10n.expensesEmpty);
              // Если страница не заполнила экран, прокрутки не будет и подгрузка
              // по скроллу не сработает — оставляем явную кнопку.
              if (_cursor != null) {
                return OutlinedButton(
                  onPressed: () => _load(reset: false),
                  child: Text(context.l10n.expensesMore),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ---------- балансы ----------

class _BalancesTab extends StatefulWidget {
  final String groupId;
  final String meId;

  const _BalancesTab({super.key, required this.groupId, required this.meId});

  @override
  State<_BalancesTab> createState() => _BalancesTabState();
}

class _BalancesTabState extends State<_BalancesTab> {
  late Future<List<Balance>> _future = _fetch();

  Future<List<Balance>> _fetch() => SessionScope.read(context).api.balances(widget.groupId);

  Future<void> _refresh() async {
    final next = _fetch();
    setState(() => _future = next);
    await next.catchError((_) => const <Balance>[]);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: FutureBuilder(
      future: _future,
      builder: (context, snapshot) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Hint(context.l10n.balancesHint),
          if (snapshot.hasError) ErrorBox(snapshot.error),
          if (snapshot.connectionState != ConnectionState.done)
            const Center(child: CircularProgressIndicator()),
          if (snapshot.data case final items?) ...[
            if (items.isEmpty) EmptyState(context.l10n.balancesEmpty),
            for (final b in items)
              Card(
                child: ListTile(
                  title: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: b.displayName),
                        if (b.userId == widget.meId)
                          TextSpan(
                            text: context.l10n.youSuffix,
                            style: const TextStyle(color: Palette.muted),
                          ),
                      ],
                    ),
                  ),
                  trailing: Money(b.balance, signed: true, style: const TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

// ---------- расчёт ----------

class _SettleTab extends StatefulWidget {
  final String groupId;
  final String meId;
  final String Function(String userId) nameOf;
  final VoidCallback onChanged;

  const _SettleTab({
    super.key,
    required this.groupId,
    required this.meId,
    required this.nameOf,
    required this.onChanged,
  });

  @override
  State<_SettleTab> createState() => _SettleTabState();
}

class _SettleTabState extends State<_SettleTab> {
  late Future<List<Transfer>> _future = _fetch();
  final _keys = IdempotencyKeys();
  Transfer? _sending;

  Future<List<Transfer>> _fetch() => SessionScope.read(context).api.plan(widget.groupId);

  Future<void> _refresh() async {
    final next = _fetch();
    setState(() => _future = next);
    await next.catchError((_) => const <Transfer>[]);
  }

  Future<void> _settle(Transfer t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settleConfirm),
        content: Text(context.l10n.settleConfirmText(widget.nameOf(t.to), t.amount)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.settleConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // Ключ привязан к самому переводу: повтор после сбоя связи сервер
    // узнает и не проведёт деньги второй раз.
    final operation = (t.from, t.to, t.amount);
    setState(() => _sending = t);
    try {
      await SessionScope.read(context).api.settle(widget.groupId, t, idempotencyKey: _keys.keyFor(operation));
      _keys.done(operation);
      widget.onChanged(); // пересоздаст эту вкладку и балансы
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _sending = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: FutureBuilder(
      future: _future,
      builder: (context, snapshot) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Hint(context.l10n.settleHint),
          if (snapshot.hasError) ErrorBox(snapshot.error),
          if (snapshot.connectionState != ConnectionState.done)
            const Center(child: CircularProgressIndicator()),
          if (snapshot.data case final items?) ...[
            if (items.isEmpty) EmptyState(context.l10n.settleEmpty),
            for (final t in items) _transfer(t),
          ],
        ],
      ),
    ),
  );

  Widget _transfer(Transfer t) {
    final mine = t.from == widget.meId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: widget.nameOf(t.from),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(
                          text: '  →  ',
                          style: TextStyle(color: Palette.muted),
                        ),
                        TextSpan(
                          text: t.to == widget.meId ? context.l10n.settleToYou : widget.nameOf(t.to),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                Money(t.amount, style: const TextStyle(fontSize: 16)),
              ],
            ),
            if (mine) ...[
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: _sending == null ? () => _settle(t) : null,
                child: _sending == t ? const ButtonProgress() : Text(context.l10n.settlePaid),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
