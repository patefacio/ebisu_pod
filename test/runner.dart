import 'package:logging/logging.dart';
import 'test_pod.dart' as test_pod;
import 'test_package.dart' as test_package;
import 'test_example.dart' as test_example;
import 'test_pod_cpp_mapper.dart' as test_pod_cpp_mapper;

main() {
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test_pod.main();
  test_package.main();
  test_example.main();
  test_pod_cpp_mapper.main();
}
