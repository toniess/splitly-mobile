import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/models.dart';
import '../session.dart';
import '../support.dart';
import '../ui/common.dart';
import '../ui/theme.dart';
import 'group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<GroupSummary>? _groups;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final groups = await SessionScope.read(context).api.groups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _open(String groupId) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupScreen(groupId: groupId)));
    // Из группы могли выйти или переименовать её — список стоит обновить.
    _load();
  }

  Future<void> _create() async {
    final group = await showModalBottomSheet<Group>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateGroupSheet(),
    );
    if (group != null) _open(group.id);
  }

  Future<void> _join() async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _JoinGroupSheet(),
    );
    if (joined == true) _load();
  }

  /// Удаление аккаунта — по запросу на почту: эндпоинта на бэкенде нет, и
  /// удаляют вручную. Письмо уже заполнено почтой и id, чтобы найти аккаунт
  /// без переписки. Нет почтового приложения — открываем страницу с инструкцией.
  Future<void> _deleteAccount() async {
    final me = SessionScope.read(context).me;
    if (me == null) return;
    final l = context.l10n;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.accountDeleteTitle),
        content: Text(l.accountDeleteText(supportEmail)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Palette.bad),
            child: Text(l.accountDeleteWrite),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final mail = Uri(
      scheme: 'mailto',
      path: supportEmail,
      // queryParameters кодирует пробелы как «+», почтовые клиенты так не понимают
      query:
          'subject=${Uri.encodeComponent(l.accountDeleteSubject)}'
          '&body=${Uri.encodeComponent(l.accountDeleteBody(me.email, me.id))}',
    );
    if (!await launchUrl(mail)) {
      await launchUrl(deleteAccountUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final groups = _groups;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.groupsTitle),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.account_circle_outlined),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(session.me?.displayName ?? '', style: const TextStyle(color: Palette.muted)),
              ),
              PopupMenuItem(
                onTap: session.logout,
                child: Text(session.isDemo ? context.l10n.groupsLogoutDemo : context.l10n.groupsLogout),
              ),
              PopupMenuItem(
                onTap: () => launchUrl(privacyPolicyUrl, mode: LaunchMode.externalApplication),
                child: Text(context.l10n.privacyPolicy),
              ),
              // В демо удалять нечего: аккаунта на сервере нет.
              if (!session.isDemo)
                PopupMenuItem(
                  onTap: _deleteAccount,
                  child: Text(context.l10n.accountDelete, style: const TextStyle(color: Palette.bad)),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.groupsNew),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          // Тянуть для обновления можно и по пустому списку.
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (session.isDemo) const _DemoBanner(),
            ErrorBox(_error),
            if (groups == null && _error == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (groups != null && groups.isEmpty) EmptyState(context.l10n.groupsEmpty),
            for (final g in groups ?? const <GroupSummary>[])
              Card(
                child: ListTile(
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: _Chip(g.currency),
                  onTap: () => _open(g.id),
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _join,
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: Text(context.l10n.groupsJoinByCode),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Palette.accent.withValues(alpha: 0.1),
      border: Border.all(color: Palette.accent.withValues(alpha: 0.4)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(context.l10n.demoBanner, style: const TextStyle(fontSize: 13)),
  );
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Palette.panel2,
      border: Border.all(color: Palette.line),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Palette.muted)),
  );
}

/// Каркас нижней панели с формой: отступ под клавиатуру и заголовок.
class _Sheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Sheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

const _currencies = ['UZS', 'USD', 'EUR', 'RUB'];

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _name = TextEditingController();
  String _currency = _currencies.first;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final group = await SessionScope.read(context).api.createGroup(_name.text.trim(), _currency);
      if (mounted) Navigator.of(context).pop(group);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: context.l10n.groupsNew,
    children: [
      ErrorBox(_error),
      TextField(
        controller: _name,
        autofocus: true,
        maxLength: 100,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: context.l10n.groupName, hintText: context.l10n.groupNameHint),
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 4),
      SegmentedButton<String>(
        segments: [for (final c in _currencies) ButtonSegment(value: c, label: Text(c))],
        selected: {_currency},
        showSelectedIcon: false,
        onSelectionChanged: (s) => setState(() => _currency = s.first),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: _busy ? const ButtonProgress() : Text(context.l10n.groupCreate),
      ),
    ],
  );
}

class _JoinGroupSheet extends StatefulWidget {
  const _JoinGroupSheet();

  @override
  State<_JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<_JoinGroupSheet> {
  final _code = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.read(context).api.joinGroup(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: context.l10n.groupJoinTitle,
    children: [
      ErrorBox(_error),
      TextField(
        controller: _code,
        autofocus: true,
        autocorrect: false,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: context.l10n.groupInviteCode, hintText: 'XFVYNZ'),
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: _busy ? const ButtonProgress() : Text(context.l10n.groupJoin),
      ),
    ],
  );
}
