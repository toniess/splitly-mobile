import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'splitly_api.dart';

/// Адрес бэкенда. Для локального сервера:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:8080   (Android-эмулятор)
///   flutter run --dart-define=API_BASE=http://localhost:8080  (iOS-симулятор)
const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'https://splitly.containerapps.ru');

/// Токены лежат в Keychain / Keystore, а не в обычных настройках:
/// refresh-токен живёт долго и равен паролю.
///
/// Keychain на iOS переживает удаление приложения, и после переустановки
/// пользователь оказался бы залогинен чужой — или просто забытой — сессией.
/// Поэтому рядом в обычных настройках лежит флаг установки: настройки
/// удаляются вместе с приложением. Нет флага — это первый запуск после
/// установки, и всё, что нашлось в Keychain, — наследство прошлой установки.
class TokenStore {
  static const _accessKey = 'splitly.access';
  static const _refreshKey = 'splitly.refresh';
  static const _installedKey = 'splitly.installed';

  final FlutterSecureStorage _storage;
  final SharedPreferencesAsync _prefs;

  TokenStore({FlutterSecureStorage? storage, SharedPreferencesAsync? prefs})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Токены не уезжают в iCloud-бэкап на другое устройство и доступны
            // после первой разблокировки — например, при фоновом обновлении.
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          ),
      _prefs = prefs ?? SharedPreferencesAsync();

  // Кэш в памяти: читать Keychain на каждый запрос дорого.
  String? _access;
  String? _refresh;
  Future<void>? _loading;

  // Один общий Future: параллельные запросы на старте не должны дважды
  // проверять флаг и чистить Keychain.
  Future<void> _load() => _loading ??= () async {
    if (await _prefs.getBool(_installedKey) != true) {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      await _prefs.setBool(_installedKey, true);
      return;
    }
    _access = await _storage.read(key: _accessKey);
    _refresh = await _storage.read(key: _refreshKey);
  }();

  Future<String?> get access async {
    await _load();
    return _access;
  }

  Future<String?> get refresh async {
    await _load();
    return _refresh;
  }

  Future<void> save(TokenPair pair) async {
    await _load();
    _access = pair.accessToken;
    _refresh = pair.refreshToken;
    await _storage.write(key: _accessKey, value: pair.accessToken);
    await _storage.write(key: _refreshKey, value: pair.refreshToken);
  }

  Future<void> clear() async {
    await _load();
    _access = null;
    _refresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

class HttpSplitlyApi implements SplitlyApi {
  final http.Client _http;
  final TokenStore _tokens;

  /// Сервер сессию не помнит: при 401 после неудачного refresh экран входа
  /// должен узнать, что пора разлогиниться.
  final void Function()? onSessionExpired;

  HttpSplitlyApi({http.Client? client, TokenStore? tokens, this.onSessionExpired})
    : _http = client ?? http.Client(),
      _tokens = tokens ?? TokenStore();

  Future<bool>? _refreshing;

  /// Обновляет пару токенов. Одновременные 401 не должны порождать несколько
  /// обновлений: refresh-токен одноразовый, второй запрос получил бы отказ,
  /// а бэкенд счёл бы это повторным использованием и отозвал всю сессию.
  Future<bool> _refreshTokens() {
    return _refreshing ??= () async {
      try {
        final refresh = await _tokens.refresh;
        if (refresh == null) return false;
        final response = await _http
            .post(
              Uri.parse('$apiBase/api/v1/auth/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh': refresh}),
            )
            .timeout(_timeout);
        // 400/401 — сервер отверг сам токен: сессия действительно кончилась.
        // 429 и 5xx — временный сбой, выкидывать пользователя на вход из-за
        // проснувшейся базы или лимита запросов нельзя.
        if (response.statusCode == 400 || response.statusCode == 401) return false;
        if (response.statusCode != 200) throw _error(response);
        await _tokens.save(TokenPair.fromJson(jsonDecode(utf8.decode(response.bodyBytes))));
        return true;
      } finally {
        // Сетевые ошибки не глушим: пропала связь — это не повод выкидывать
        // пользователя из сессии, пусть долетят до вызывающего как обычный сбой.
        _refreshing = null;
      }
    }();
  }

  // Neon на бесплатном тарифе просыпается секунд десять — запас с избытком.
  static const _timeout = Duration(seconds: 30);

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
    String? idempotencyKey,
  }) async {
    final uri = Uri.parse('$apiBase$path').replace(queryParameters: query);

    Future<http.Response> send() async {
      final request = http.Request(method, uri);
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final access = auth ? await _tokens.access : null;
      if (access != null) request.headers['Authorization'] = 'Bearer $access';
      if (idempotencyKey != null) request.headers['Idempotency-Key'] = idempotencyKey;
      // Таймаут на весь ответ целиком, а не только на заголовки.
      return _http.send(request).then(http.Response.fromStream).timeout(_timeout);
    }

    http.Response response;
    try {
      response = await send();

      // Токен живёт 15 минут. Истёк — молча обновляем и повторяем один раз.
      if (response.statusCode == 401 && auth) {
        if (await _refreshTokens()) {
          response = await send();
        } else {
          await _tokens.clear();
          onSessionExpired?.call();
        }
      }
    } on SocketException {
      throw const ApiError(kind: ApiErrorKind.offline, status: 0);
    } on TimeoutException {
      throw const ApiError(kind: ApiErrorKind.timeout, status: 0);
    } on http.ClientException catch (e) {
      throw ApiError(kind: ApiErrorKind.network, status: 0, detail: e.message);
    }

    if (response.statusCode >= 400) throw _error(response);
    final text = utf8.decode(response.bodyBytes);
    final payload = text.isEmpty ? null : jsonDecode(text);
    return payload;
  }

  /// Ошибка RFC 7807. Тело может оказаться и не JSON — например, HTML-страница
  /// 502 от прокси перед сервером, — тогда хватит кода ответа.
  static ApiError _error(http.Response response) {
    Map<String, dynamic> map = const {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) map = decoded;
    } on FormatException {
      // не JSON — остаёмся с пустой картой
    }
    final errors = map['errors'];
    return ApiError(
      status: response.statusCode,
      title: map['title'] as String? ?? '',
      detail: map['detail'] as String? ?? '',
      traceId: map['traceId'] as String?,
      fields: errors is List
          ? errors
                .whereType<Map<String, dynamic>>()
                .map((e) => (field: '${e['field']}', message: '${e['message']}'))
                .toList()
          : const [],
    );
  }

  @override
  Future<void> register(String email, String password, String displayName) => _request(
    'POST',
    '/api/v1/auth/register',
    body: {'email': email, 'password': password, 'displayName': displayName},
    auth: false,
  );

  @override
  Future<void> login(String email, String password) async {
    final json = await _request(
      'POST',
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    await _tokens.save(TokenPair.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> logout() => _tokens.clear();

  @override
  Future<bool> hasSession() async => await _tokens.access != null;

  @override
  Future<User> me() async => User.fromJson(await _request('GET', '/api/v1/users/me'));

  @override
  Future<List<GroupSummary>> groups() async {
    final json = await _request('GET', '/api/v1/groups') as List;
    return json.map((e) => GroupSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Group> group(String id) async => Group.fromJson(await _request('GET', '/api/v1/groups/$id'));

  @override
  Future<Group> createGroup(String name, String currency) async =>
      Group.fromJson(await _request('POST', '/api/v1/groups', body: {'name': name, 'currency': currency}));

  @override
  Future<void> joinGroup(String inviteCode) =>
      _request('POST', '/api/v1/groups/join', body: {'inviteCode': inviteCode});

  @override
  Future<List<GroupMember>> members(String groupId) async {
    final json = await _request('GET', '/api/v1/groups/$groupId/members') as List;
    return json.map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> leaveGroup(String groupId) => _request('DELETE', '/api/v1/groups/$groupId/members/me');

  @override
  Future<ExpenseFeedPage> feed(String groupId, {String? cursor, int limit = 20}) async =>
      ExpenseFeedPage.fromJson(
        await _request(
          'GET',
          '/api/v1/groups/$groupId/expenses',
          query: {'limit': '$limit', 'cursor': ?cursor},
        ),
      );

  @override
  Future<Expense> expense(String id) async => Expense.fromJson(await _request('GET', '/api/v1/expenses/$id'));

  @override
  Future<Expense> createExpense(String groupId, NewExpense body, {required String idempotencyKey}) async =>
      Expense.fromJson(
        await _request(
          'POST',
          '/api/v1/groups/$groupId/expenses',
          body: body.toJson(),
          idempotencyKey: idempotencyKey,
        ),
      );

  @override
  Future<void> deleteExpense(String id) => _request('DELETE', '/api/v1/expenses/$id');

  @override
  Future<List<Balance>> balances(String groupId) async {
    final json = await _request('GET', '/api/v1/groups/$groupId/balances');
    return (json['items'] as List).map((e) => Balance.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Transfer>> plan(String groupId) async {
    final json = await _request('GET', '/api/v1/groups/$groupId/settlement-plan');
    return (json['items'] as List).map((e) => Transfer.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> settle(String groupId, Transfer transfer, {required String idempotencyKey}) => _request(
    'POST',
    '/api/v1/groups/$groupId/settlements',
    body: {'fromUserId': transfer.from, 'toUserId': transfer.to, 'amount': transfer.amount},
    idempotencyKey: idempotencyKey,
  );
}
