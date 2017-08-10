library ebisu_pod.test_pod_rust_mapper;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu_pod/pod_rust.dart';

// end <additional imports>

final Logger _logger = new Logger('test_pod_rust_mapper');

// custom <library test_pod_rust_mapper>
// end <library test_pod_rust_mapper>

void main([List<String> args]) {
  if (args?.isEmpty ?? false) {
    Logger.root.onRecord.listen(
        (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
    Logger.root.level = Level.OFF;
  }
// custom <main>

  test('field types', () {
    final po = object('all_types', [
      field('a_char', Char),
      field('a_double', Double),
      field('object_id', ObjectId),
      field('boolean', Boolean),
      field('date', Date),
      field('regex', Regex),
      field('int8', Int8),
      field('int16', Int16),
      field('int32', Int32),
      field('int64', Int64),
      field('uint8', Uint8),
      field('uint16', Uint16),
      field('uint32', Uint32),
      field('uint64', Uint64),
      field('date_time', DateTime),
      field('timestamp', Timestamp),
      field('fixed_size_str', fixedStr(10)),
      field('fixed_size_double', array(Double, maxLength: 12)),
      field('var_size_double', array(Double)),
      bitSetField('bs', 4, rhsPadBits: 2),
    ]);

    final pkg = new PodPackage('sample', namedTypes: [
      po,
      enum_('foo', ['a', 'b', 'c']),
    ]);
    final mapper = new PodRustMapper(pkg);

    print(mapper.module.code);
  });

// end <main>
}
