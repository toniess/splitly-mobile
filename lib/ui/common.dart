import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/splitly_api.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Показ ошибки API с traceId — по нему ошибку находят в логах сервера.
class ErrorBox extends StatelessWidget {
  final Object? error;

  const ErrorBox(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    if (error == null) return const SizedBox.shrink();

    final traceId = error is ApiError ? error.traceId : null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.bad.withValues(alpha: 0.1),
        border: Border.all(color: Palette.bad.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(errorText(context, error), style: const TextStyle(color: Palette.bad)),
          if (traceId != null)
            SelectableText(
              'traceId: $traceId',
              style: const TextStyle(color: Palette.muted, fontSize: 11, fontFamily: 'monospace'),
            ),
        ],
      ),
    );
  }
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Текст ошибки на языке интерфейса. Сбои до сервера клиент описывает сам;
/// тексты ошибок сервера показываются как есть — их язык выбирает бэкенд.
String errorText(BuildContext context, Object error) {
  if (error is! ApiError) return '$error';
  final l = context.l10n;
  return switch (error.kind) {
    ApiErrorKind.offline => l.errorOffline,
    ApiErrorKind.timeout => l.errorTimeout,
    ApiErrorKind.network => l.errorNetwork,
    ApiErrorKind.server => error.humanMessage.isNotEmpty ? error.humanMessage : l.errorServer(error.status),
  };
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(context, error))));
}

/// Сумма как пришла с сервера. При [signed] плюс — зелёный, минус — красный.
class Money extends StatelessWidget {
  final String value;
  final bool signed;
  final TextStyle? style;

  const Money(this.value, {super.key, this.signed = false, this.style});

  @override
  Widget build(BuildContext context) {
    final sign = _sign(value);
    final color = !signed
        ? Palette.text
        : sign > 0
        ? Palette.ok
        : sign < 0
        ? Palette.bad
        : Palette.muted;
    return Text(
      signed && sign > 0 ? '+$value' : value,
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
      ).merge(style).copyWith(color: color),
    );
  }

  /// Знак суммы без перевода в double: достаточно посмотреть на цифры.
  static int _sign(String value) {
    if (!RegExp(r'[1-9]').hasMatch(value)) return 0;
    return value.trim().startsWith('-') ? -1 : 1;
  }
}

/// «3 окт. 2026 г.» / «Oct 3, 2026» — по языку интерфейса.
String formatDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date.toLocal());

class EmptyState extends StatelessWidget {
  final String text;

  const EmptyState(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Palette.muted),
    ),
  );
}

class Hint extends StatelessWidget {
  final String text;

  const Hint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(color: Palette.muted, fontSize: 13)),
  );
}

/// Индикатор на кнопке, пока идёт запрос.
class ButtonProgress extends StatelessWidget {
  const ButtonProgress({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2));
}

/// Запоминает выпавший ключ идемпотентности до успеха, чтобы повтор
/// той же операции после сетевой ошибки ушёл с тем же ключом.
///
/// Веб-клиент генерирует ключ на каждый запрос заново, и повтор после
/// таймаута там создал бы дубль. Здесь ключ живёт, пока операция не прошла.
class IdempotencyKeys {
  final _keys = <Object, String>{};

  String keyFor(Object operation) => _keys.putIfAbsent(operation, newIdempotencyKey);

  void done(Object operation) => _keys.remove(operation);
}
