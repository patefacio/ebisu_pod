import 'package:logging/logging.dart';
import 'test_pod.dart' as test_pod;
import 'test_package.dart' as test_package;
import 'test_example.dart' as test_example;
import 'test_max_length.dart' as test_max_length;
import 'test_bitset.dart' as test_bitset;
import 'test_pod_cpp_mapper.dart' as test_pod_cpp_mapper;
import 'test_pod_dart_mapper.dart' as test_pod_dart_mapper;
import 'test_pod_rust_mapper.dart' as test_pod_rust_mapper;
import 'test_properties.dart' as test_properties;

void main() {
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test_pod.main(null);
  test_package.main(null);
  test_example.main(null);
  test_max_length.main(null);
  test_bitset.main(null);
  test_pod_cpp_mapper.main(null);
  test_pod_dart_mapper.main(null);
  test_pod_rust_mapper.main(null);
  test_properties.main(null);
}
