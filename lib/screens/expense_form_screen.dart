import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/models.dart';
import '../api/splitly_api.dart';
import '../session.dart';
import '../ui/common.dart';
import '../ui/theme.dart';

/// Сумма с не более чем двумя знаками после точки — как `@Digits(fraction = 2)` на бэкенде.
final _moneyPattern = RegExp(r'^\d{1,15}([.,]\d{0,2})?$');

String _normalizeMoney(String value) => value.trim().replaceAll(',', '.');

/// Добавление траты. Возвращает `true`, если трата сохранилась.
class ExpenseFormScreen extends StatefulWidget {
  final String groupId;
  final String meId;
  final List<GroupMember> members;

  const ExpenseFormScreen({super.key, required this.groupId, required this.meId, required this.members});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  late final Map<String, TextEditingController> _values = {
    for (final m in widget.members) m.userId: TextEditingController(),
  };

  late String _payerId = widget.members.any((m) => m.userId == widget.meId)
      ? widget.meId
      : widget.members.first.userId;
  late final Set<String> _chosen = {for (final m in widget.members) m.userId};
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  SplitType _splitType = SplitType.equal;

  bool _busy = false;
  Object? _error;

  /// Последняя неудачная попытка: если пользователь жмёт «Сохранить» ещё раз,
  /// не меняя формы, запрос уходит с тем же ключом и тем же моментом траты.
  /// Сервер узнает повтор и не создаст вторую трату, даже если первая на самом
  /// деле дошла, а оборвался только ответ.
  ({String fingerprint, String key, DateTime spentAt})? _pending;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 5),
      // Сервер отклоняет траты из будущего (@PastOrPresent).
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  List<Participant> _participants() => [
    for (final m in widget.members)
      if (_chosen.contains(m.userId))
        Participant(
          m.userId,
          // при равном делении сервер считает доли сам
          _splitType == SplitType.equal ? null : _normalizeMoney(_values[m.userId]!.text).ifEmpty('0'),
        ),
  ];

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_chosen.isEmpty) {
      setState(() => _error = context.l10n.formNoParticipants);
      return;
    }

    final participants = _participants();
    // Нулевые доли у всех сервер сейчас отвечает 500, а не 422, — ловим заранее.
    if (_splitType == SplitType.shares && participants.every((p) => int.tryParse(p.value ?? '0') == 0)) {
      setState(() => _error = context.l10n.formZeroShares);
      return;
    }
    final fingerprint = jsonEncode([
      _description.text.trim(),
      _normalizeMoney(_amount.text),
      _payerId,
      _date.toIso8601String(),
      _splitType.wire,
      [for (final p in participants) p.toJson()],
    ]);

    final pending = _pending?.fingerprint == fingerprint
        ? _pending!
        : (
            fingerprint: fingerprint,
            key: newIdempotencyKey(),
            // Для сегодняшней даты — текущий момент. Для прошлой — полдень того
            // дня: полночь по UTC в другом часовом поясе уехала бы на соседние сутки.
            spentAt: DateUtils.isSameDay(_date, DateTime.now())
                ? _todayMoment()
                : _date.add(const Duration(hours: 12)),
          );
    _pending = pending;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.read(context).api.createExpense(
        widget.groupId,
        NewExpense(
          description: _description.text.trim(),
          amount: _normalizeMoney(_amount.text),
          payerId: _payerId,
          spentAt: pending.spentAt,
          splitType: _splitType,
          participants: participants,
        ),
        idempotencyKey: pending.key,
      );
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

  /// Момент «сейчас» с запасом в пару минут: сервер проверяет @PastOrPresent
  /// по своим часам, и телефон, спешащий на несколько секунд, получил бы отказ.
  /// Запас не уводит трату во вчерашний день.
  static DateTime _todayMoment() {
    final now = DateTime.now();
    final shifted = now.subtract(const Duration(minutes: 2));
    final midnight = DateUtils.dateOnly(now);
    return shifted.isBefore(midnight) ? midnight : shifted;
  }

  String? _validateValue(String? value) {
    final text = _normalizeMoney(value ?? '');
    if (text.isEmpty) return null; // пустое поле уходит как 0, решит сервер
    return switch (_splitType) {
      SplitType.shares => RegExp(r'^\d+$').hasMatch(text) ? null : context.l10n.formShareInteger,
      SplitType.exact => _moneyPattern.hasMatch(text) ? null : '0.00',
      SplitType.equal => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.isSameDay(_date, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.formTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBox(_error),
            TextFormField(
              controller: _description,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.formWhat,
                hintText: context.l10n.formWhatHint,
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.formWhatRequired : null,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    decoration: InputDecoration(labelText: context.l10n.formAmount, hintText: '300.00'),
                    validator: (v) {
                      final text = _normalizeMoney(v ?? '');
                      if (!_moneyPattern.hasMatch(text)) return context.l10n.formAmountInvalid;
                      if (!RegExp(r'[1-9]').hasMatch(text)) return context.l10n.formAmountPositive;
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: context.l10n.formWhen),
                      child: Text(today ? context.l10n.formToday : formatDate(context, _date)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _payerId,
              decoration: InputDecoration(labelText: context.l10n.formPayer),
              items: [
                for (final m in widget.members)
                  DropdownMenuItem(
                    value: m.userId,
                    child: Text(
                      m.userId == widget.meId ? context.l10n.nameWithYou(m.displayName) : m.displayName,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _payerId = v!),
            ),
            const SizedBox(height: 16),
            SegmentedButton<SplitType>(
              segments: [
                ButtonSegment(value: SplitType.equal, label: Text(context.l10n.splitEqualShort)),
                ButtonSegment(value: SplitType.shares, label: Text(context.l10n.splitSharesShort)),
                ButtonSegment(value: SplitType.exact, label: Text(context.l10n.splitExactShort)),
              ],
              selected: {_splitType},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _splitType = s.first),
            ),
            const SizedBox(height: 16),
            Text(switch (_splitType) {
              SplitType.equal => context.l10n.formBetween,
              SplitType.shares => context.l10n.formBetweenShares,
              SplitType.exact => context.l10n.formBetweenExact,
            }, style: const TextStyle(color: Palette.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final m in widget.members) _participantRow(m),
            if (_splitType == SplitType.exact)
              _ExactHint(total: _amount.text, values: [for (final id in _chosen) _values[id]!.text]),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy || _chosen.isEmpty ? null : _submit,
              child: _busy ? const ButtonProgress() : Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _participantRow(GroupMember m) {
    final chosen = _chosen.contains(m.userId);
    return Row(
      children: [
        Checkbox(
          value: chosen,
          onChanged: (v) => setState(() => v! ? _chosen.add(m.userId) : _chosen.remove(m.userId)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => chosen ? _chosen.remove(m.userId) : _chosen.add(m.userId)),
            child: Text(m.userId == widget.meId ? context.l10n.nameWithYou(m.displayName) : m.displayName),
          ),
        ),
        if (_splitType != SplitType.equal && chosen)
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: _values[m.userId],
              textAlign: TextAlign.end,
              keyboardType: TextInputType.numberWithOptions(decimal: _splitType == SplitType.exact),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              decoration: InputDecoration(hintText: _splitType == SplitType.shares ? '1' : '0.00'),
              validator: _validateValue,
              onChanged: (_) => setState(() {}),
            ),
          ),
      ],
    );
  }
}

/// Подсказка при делении точными суммами: сколько ещё осталось распределить.
///
/// Это единственное место, где клиент сам складывает деньги, и только ради
/// подсказки — проверку «сумма долей равна сумме траты» всё равно делает сервер.
class _ExactHint extends StatelessWidget {
  final String total;
  final List<String> values;

  const _ExactHint({required this.total, required this.values});

  static int? _cents(String value) {
    final text = _normalizeMoney(value);
    if (text.isEmpty) return 0;
    if (!_moneyPattern.hasMatch(text)) return null;
    final parts = text.split('.');
    final fraction = parts.length > 1 ? '${parts[1]}00'.substring(0, 2) : '00';
    return int.parse(parts[0]) * 100 + int.parse(fraction);
  }

  static String _format(int cents) {
    final abs = cents.abs();
    return '${cents < 0 ? '-' : ''}${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalCents = _cents(total);
    final parts = values.map(_cents).toList();
    if (totalCents == null || totalCents == 0 || parts.contains(null)) return const SizedBox.shrink();

    final left = totalCents - parts.fold<int>(0, (a, b) => a + b!);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        left == 0
            ? context.l10n.formExactDone
            : left > 0
            ? context.l10n.formExactLeft(_format(left))
            : context.l10n.formExactOver(_format(-left)),
        style: TextStyle(color: left == 0 ? Palette.ok : Palette.bad, fontSize: 13),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
