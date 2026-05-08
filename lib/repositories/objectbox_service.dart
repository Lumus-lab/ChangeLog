import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../objectbox.g.dart';

class ObjectBoxService {
  /// The Store of this app.
  late final Store store;

  ObjectBoxService._create(this.store);

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBoxService> create() async {
    final supportDir = await getApplicationSupportDirectory();
    final storeDir = storeDirectoryFor(supportDir);
    storeDir.createSync(recursive: true);
    final store = await openStore(directory: storeDir.path);
    return ObjectBoxService._create(store);
  }

  static Directory storeDirectoryFor(Directory applicationSupportDirectory) {
    return Directory(p.join(applicationSupportDirectory.path, "obx_changelog"));
  }
}
