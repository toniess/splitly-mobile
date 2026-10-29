import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Складывает скриншоты из integration_test/screenshots_test.dart в store/screenshots.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('store/screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
