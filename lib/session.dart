import 'package:flutter/widgets.dart';

import 'api/demo_api.dart';
import 'api/http_api.dart';
import 'api/models.dart';
import 'api/splitly_api.dart';
import 'l10n/app_localizations.dart';

/// Кто вошёл и через какой клиент ходим. Единственное общее состояние
/// приложения — всё остальное экраны держат у себя.
class Session extends ChangeNotifier {
  late final HttpSplitlyApi _real = HttpSplitlyApi(onSessionExpired: _expired);
  DemoSplitlyApi? _demo;

  User? _me;
  bool _checked = false;

  SplitlyApi get api => _demo ?? _real;
  User? get me => _me;
  bool get isDemo => _demo != null;

  /// Проверили ли сохранённую сессию на старте. До этого показываем заставку.
  bool get checked => _checked;

  /// Токен может лежать в Keychain с прошлого запуска — проверяем, жив ли он,
  /// одним запросом к /users/me.
  Future<void> restore() async {
    try {
      if (await _real.hasSession()) _me = await _real.me();
    } on ApiError catch (e) {
      // Нет сети — не повод забывать токены: пусть пользователь увидит
      // экран входа, а при следующем запуске сессия поднимется.
      if (e.status != 0) await _real.logout();
    } finally {
      _checked = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await _real.login(email, password);
    _me = await _real.me();
    notifyListeners();
  }

  /// Бэкенд на регистрацию возвращает только userId, без токенов, поэтому
  /// сразу же логинимся теми же данными.
  Future<void> register(String email, String password, String displayName) async {
    await _real.register(email, password, displayName);
    await login(email, password);
  }

  /// [l10n] — язык, на котором песочница назовёт группу, участников и траты.
  Future<void> startDemo(AppLocalizations l10n) async {
    _demo = DemoSplitlyApi(l10n);
    _me = await _demo!.me();
    _checked = true;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_demo == null) await _real.logout();
    _demo = null;
    _me = null;
    notifyListeners();
  }

  void _expired() {
    if (_demo != null || _me == null) return;
    _me = null;
    notifyListeners();
  }
}

class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  /// Без подписки на изменения — для обработчиков нажатий.
  static Session read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
