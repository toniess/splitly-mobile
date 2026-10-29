import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/groups_screen.dart';
import 'session.dart';
import 'ui/theme.dart';

void main() {
  // restore() читает Keychain через platform channel — нужен готовый binding.
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session()..restore();
  runApp(SplitlyApp(session: session));
}

class SplitlyApp extends StatefulWidget {
  final Session session;

  const SplitlyApp({super.key, required this.session});

  @override
  State<SplitlyApp> createState() => _SplitlyAppState();
}

class _SplitlyAppState extends State<SplitlyApp> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  /// Сессия кончилась — выход или отозванный refresh-токен, пока пользователь
  /// смотрит группу. Смена `home` не убирает открытые поверх него экраны,
  /// поэтому снимаем их сами: иначе вход окажется под экраном группы.
  void _onSession() {
    if (widget.session.me == null) _navigator.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: widget.session,
      child: MaterialApp(
        navigatorKey: _navigator,
        title: 'Splitly',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeListResolutionCallback: resolveLocale,
        home: const _Root(),
      ),
    );
  }
}

/// Языки, носители которых чаще читают по-русски, чем по-английски.
const _russianSpeaking = {'ru', 'uz', 'kk', 'ky', 'tg', 'tk', 'be', 'uk', 'az', 'hy', 'ka', 'mn'};

/// Первый язык из настроек системы, который мы знаем, — английский или русский.
/// Иначе по первому языку системы: для СНГ — русский, для остальных — английский.
/// Стандартное правило Flutter отдало бы немцу русский интерфейс просто потому,
/// что русский идёт первым в списке поддерживаемых.
Locale resolveLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    if (locale.languageCode == 'ru') return const Locale('ru');
    if (locale.languageCode == 'en') return const Locale('en');
  }
  final first = preferred?.firstOrNull?.languageCode;
  return _russianSpeaking.contains(first) ? const Locale('ru') : const Locale('en');
}

/// Переключает вход и основной экран по состоянию сессии.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return session.me == null ? const AuthScreen() : const GroupsScreen();
  }
}
