import 'package:flutter/material.dart';

import '../api/models.dart';
import '../session.dart';
import '../ui/common.dart';
import '../ui/theme.dart';

/// Трата целиком: кто платил и как разделили. Возвращает `true`, если трату удалили.
class ExpenseScreen extends StatefulWidget {
  final String expenseId;
  final String Function(String userId) nameOf;

  const ExpenseScreen({super.key, required this.expenseId, required this.nameOf});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late final Future<Expense> _future = SessionScope.read(context).api.expense(widget.expenseId);
  bool _deleting = false;

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.expenseDeleteConfirm),
        content: Text(context.l10n.expenseDeleteHint),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Palette.bad),
            child: Text(context.l10n.expenseDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await SessionScope.read(context).api.deleteExpense(widget.expenseId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.expenseTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.expenseDelete,
            onPressed: _deleting ? null : _delete,
            icon: _deleting ? const ButtonProgress() : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(padding: const EdgeInsets.all(16), child: ErrorBox(snapshot.error));
          }
          final e = snapshot.data;
          if (e == null) return const Center(child: CircularProgressIndicator());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(e.description, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Money(e.amount, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(e.currency, style: const TextStyle(color: Palette.muted, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.expensePaidBy(widget.nameOf(e.payerId), formatDate(context, e.spentAt)),
                style: const TextStyle(color: Palette.muted),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.expenseShares(switch (e.splitType) {
                  SplitType.equal => context.l10n.splitEqual,
                  SplitType.shares => context.l10n.splitShares,
                  SplitType.exact => context.l10n.splitExact,
                }),
                style: const TextStyle(color: Palette.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final s in e.shares)
                      ListTile(dense: true, title: Text(s.displayName), trailing: Money(s.amount)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
