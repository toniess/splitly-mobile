import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:splitly/api/http_api.dart';
import 'package:splitly/api/models.dart';
import 'package:splitly/api/splitly_api.dart';

/// Хранилище токенов в памяти вместо Keychain.
class MemoryTokens implements TokenStore {
  String? _access;
  String? _refresh;

  MemoryTokens([this._access, this._refresh]);

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

http.Response json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

void main() {
  test('на 401 обновляет токены один раз даже при параллельных запросах', () async {
    var refreshCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh') {
        refreshCalls++;
        expect(jsonDecode(request.body), {'refresh': 'old-refresh'});
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return json({
          'accessToken': 'new',
          'refreshToken': 'new-refresh',
          'tokenType': 'Bearer',
          'expiresIn': 900,
        });
      }
      if (request.headers['Authorization'] != 'Bearer new') return json({'title': 'Unauthorized'}, 401);
      return json([]);
    });
    final tokens = MemoryTokens('old', 'old-refresh');
    final api = HttpSplitlyApi(client: client, tokens: tokens);

    await Future.wait([api.groups(), api.groups(), api.groups()]);

    expect(refreshCalls, 1);
    expect(await tokens.refresh, 'new-refresh');
  });

  test('неудачный refresh чистит токены и сообщает об истёкшей сессии', () async {
    var expired = false;
    final client = MockClient((request) async => json({'title': 'Unauthorized'}, 401));
    final tokens = MemoryTokens('old', 'old-refresh');
    final api = HttpSplitlyApi(client: client, tokens: tokens, onSessionExpired: () => expired = true);

    await expectLater(api.groups(), throwsA(isA<ApiError>().having((e) => e.status, 'status', 401)));
    expect(expired, isTrue);
    expect(await tokens.access, isNull);
  });

  test('сбой сервера на refresh не выкидывает из сессии', () async {
    var expired = false;
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh') return http.Response('', 503);
      return json({'title': 'Unauthorized'}, 401);
    });
    final tokens = MemoryTokens('old', 'old-refresh');
    final api = HttpSplitlyApi(client: client, tokens: tokens, onSessionExpired: () => expired = true);

    await expectLater(api.groups(), throwsA(isA<ApiError>().having((e) => e.status, 'status', 503)));
    expect(expired, isFalse);
    expect(await tokens.refresh, 'old-refresh');
  });

  test('HTML вместо JSON в ошибке не роняет разбор', () async {
    final client = MockClient((request) async => http.Response('<html>Bad Gateway</html>', 502));
    final api = HttpSplitlyApi(client: client, tokens: MemoryTokens('t', 'r'));

    await expectLater(
      api.groups(),
      throwsA(
        isA<ApiError>().having((e) => e.status, 'status', 502).having((e) => e.traceId, 'traceId', null),
      ),
    );
  });

  test('ошибка RFC 7807 разбирается вместе с полями и traceId', () async {
    final client = MockClient(
      (request) async => json({
        'title': 'Ошибка валидации',
        'detail': 'Запрос не прошёл проверку',
        'traceId': 'abc',
        'errors': [
          {'field': 'amount', 'message': 'must be greater than or equal to 0.01'},
        ],
      }, 400),
    );
    final api = HttpSplitlyApi(client: client, tokens: MemoryTokens('t', 'r'));

    final error = await api.groups().then<ApiError?>((_) => null, onError: (Object e) => e as ApiError);
    expect(error!.traceId, 'abc');
    expect(error.humanMessage, 'amount: must be greater than or equal to 0.01');
  });

  test('создание траты шлёт Idempotency-Key и тело в формате бэкенда', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return json({
        'id': 'e1',
        'groupId': 'g1',
        'payerId': 'u1',
        'amount': '100.00',
        'currency': 'UZS',
        'description': 'Такси',
        'spentAt': '2026-10-01T10:00:00Z',
        'splitType': 'EQUAL',
        'version': 0,
        'createdAt': '2026-10-01T10:00:00Z',
        'shares': [
          {'userId': 'u1', 'displayName': 'Я', 'amount': '100.00'},
        ],
      }, 201);
    });
    final api = HttpSplitlyApi(client: client, tokens: MemoryTokens('t', 'r'));

    final expense = await api.createExpense(
      'g1',
      NewExpense(
        description: 'Такси',
        amount: '100.00',
        payerId: 'u1',
        spentAt: DateTime.utc(2026, 10, 1, 10),
        splitType: SplitType.equal,
        participants: const [Participant('u1', null)],
      ),
      idempotencyKey: 'key-1',
    );

    expect(sent.headers['Idempotency-Key'], 'key-1');
    expect(sent.headers['Authorization'], 'Bearer t');
    expect(jsonDecode(sent.body), {
      'description': 'Такси',
      'amount': '100.00',
      'payerId': 'u1',
      'spentAt': '2026-10-01T10:00:00.000Z',
      'splitType': 'EQUAL',
      'participants': [
        {'userId': 'u1', 'value': null},
      ],
    });
    expect(expense.shares.single.amount, '100.00');
  });

  test('ключ идемпотентности — UUID v4', () {
    expect(
      newIdempotencyKey(),
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
    );
  });
}
