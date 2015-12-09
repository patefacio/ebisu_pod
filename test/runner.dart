import 'package:logging/logging.dart';
import 'test_pod.dart' as test_pod;
import 'test_package.dart' as test_package;

main() {
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test_pod.main();
  test_package.main();
}
