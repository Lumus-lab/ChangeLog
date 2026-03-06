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
    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = p.join(docsDir.path, "obx_changelog");
    Directory(storeDir).createSync(recursive: true);
    final store = await openStore(directory: storeDir);
    return ObjectBoxService._create(store);
  }
}
