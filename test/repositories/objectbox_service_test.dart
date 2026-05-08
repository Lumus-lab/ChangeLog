import 'dart:io';

import 'package:changelog/repositories/objectbox_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses application support as the ObjectBox store parent', () {
    final supportDir = Directory('/tmp/changelog-support');

    final storeDir = ObjectBoxService.storeDirectoryFor(supportDir);

    expect(storeDir.path, '/tmp/changelog-support/obx_changelog');
  });
}
