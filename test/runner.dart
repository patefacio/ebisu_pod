import 'package:logging/logging.dart';
import 'test_pod.dart' as test_pod;
import 'test_package.dart' as test_package;
import 'test_example.dart' as test_example;
import 'test_max_length.dart' as test_max_length;
import 'test_bitset.dart' as test_bitset;
import 'test_pod_cpp_mapper.dart' as test_pod_cpp_mapper;
import 'test_pod_dart_mapper.dart' as test_pod_dart_mapper;
import 'test_properties.dart' as test_properties;

main() {
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test_pod.main();
  test_package.main();
  test_example.main();
  test_max_length.main();
  test_bitset.main();
  test_pod_cpp_mapper.main();
  test_pod_dart_mapper.main();
  test_properties.main();
}
