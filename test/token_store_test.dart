import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:splitly/api/http_api.dart';
import 'package:splitly/api/models.dart';

const _pair = TokenPair(accessToken: 'a', refreshToken: 'r');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('после переустановки токены из Keychain не подхватываются и стираются', () async {
    // Keychain пережил удаление приложения, настройки — нет.
    FlutterSecureStorage.setMockInitialValues({'splitly.access': 'old', 'splitly.refresh': 'old-r'});

    final store = TokenStore();
    expect(await store.access, isNull);
    expect(await store.refresh, isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test('при обычном перезапуске сессия сохраняется', () async {
    FlutterSecureStorage.setMockInitialValues({});

    await TokenStore().save(_pair);

    // Новый процесс — новый TokenStore, настройки и Keychain те же.
    final restarted = TokenStore();
    expect(await restarted.access, 'a');
    expect(await restarted.refresh, 'r');
  });
}
