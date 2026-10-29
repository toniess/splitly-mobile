import 'dart:math';

import 'models.dart';

/// Откуда ошибка: ответ сервера или сбой до него. Сбои клиент описывает сам
/// и на языке интерфейса — API-слой контекста локализации не видит.
enum ApiErrorKind { server, offline, timeout, network }

/// Ошибка в формате RFC 7807, который отдаёт бэкенд.
class ApiError implements Exception {
  final ApiErrorKind kind;
  final int status;

  /// Пусто, если сервер ничего не объяснил — тогда UI покажет код ответа.
  final String title;
  final String detail;
  final String? traceId;
  final List<({String field, String message})> fields;

  const ApiError({
    this.kind = ApiErrorKind.server,
    required this.status,
    this.title = '',
    this.detail = '',
    this.traceId,
    this.fields = const [],
  });

  /// Текст для показа пользователю: детали полей важнее общей формулировки.
  String get humanMessage {
    if (fields.isNotEmpty) {
      return fields.map((f) => '${f.field}: ${f.message}').join('; ');
    }
    return detail.isNotEmpty ? detail : title;
  }

  @override
  String toString() => humanMessage;
}

/// Всё, что экраны умеют просить у сервера.
///
/// Реализаций две: [HttpSplitlyApi] ходит в бэкенд, [DemoSplitlyApi] держит
/// песочницу в памяти. Экраны не знают, с какой работают, поэтому в них нет
/// веток `if (demo)`.
abstract interface class SplitlyApi {
  Future<void> register(String email, String password, String displayName);

  /// Логинит и сохраняет токены — экранам их видеть незачем.
  Future<void> login(String email, String password);

  Future<void> logout();

  /// Есть ли с прошлого запуска сохранённая сессия, которую стоит проверить.
  Future<bool> hasSession();

  Future<User> me();

  Future<List<GroupSummary>> groups();
  Future<Group> group(String id);
  Future<Group> createGroup(String name, String currency);
  Future<void> joinGroup(String inviteCode);
  Future<List<GroupMember>> members(String groupId);
  Future<void> leaveGroup(String groupId);

  Future<ExpenseFeedPage> feed(String groupId, {String? cursor, int limit = 20});
  Future<Expense> expense(String id);

  /// [idempotencyKey] генерирует форма один раз на попытку сохранить. Повтор
  /// после обрыва связи уходит с тем же ключом, и вторая трата не появится.
  Future<Expense> createExpense(String groupId, NewExpense body, {required String idempotencyKey});
  Future<void> deleteExpense(String id);

  Future<List<Balance>> balances(String groupId);
  Future<List<Transfer>> plan(String groupId);
  Future<void> settle(String groupId, Transfer transfer, {required String idempotencyKey});
}

final _random = Random.secure();

/// UUID v4 для `Idempotency-Key`. Ради одной функции тянуть пакет незачем.
String newIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
