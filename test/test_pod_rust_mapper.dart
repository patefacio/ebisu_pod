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
      // TODO: field('object_id', ObjectId),
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
      // TODO: field('fixed_size_str', fixedStr(10)),
      field('fixed_size_double', array(Double, maxLength: 12)),
      field('var_size_double', array(Double)),
      // TODO: bitSetField('bs', 4, rhsPadBits: 2),
    ]);

    final pkg = new PodPackage('sample', namedTypes: [
      po,
      enum_('foo', ['a', 'b', 'c']),
    ]);
    final mapper = new PodRustMapper(pkg);

    expect(darkMatter(mapper.module.code), darkMatter('''
/// TODO: comment module sample
/// TODO: comment foo
#[derive(Debug)]
enum Foo {
    /// TODO: comment a
    A,
    /// TODO: comment b
    B,
    /// TODO: comment c
    C,
}
/// TODO: comment struct allTypes
#[derive(Debug, Clone, Serialize, Deserialize)]
struct AllTypes {
  /// TODO: comment field
  a_char: char,
  /// TODO: comment field
  a_double: f64,
  /// TODO: comment field
  boolean: bool,
  /// TODO: comment field
  date: chrono::Date<chrono::Utc>,
  /// TODO: comment field
  regex: regex::Regex,
  /// TODO: comment field
  int8: i8,
  /// TODO: comment field
  int16: i16,
  /// TODO: comment field
  int32: i32,
  /// TODO: comment field
  int64: i64,
  /// TODO: comment field
  uint8: u8,
  /// TODO: comment field
  uint16: u16,
  /// TODO: comment field
  uint32: u32,
  /// TODO: comment field
  uint64: u64,
  /// TODO: comment field
  date_time: chrono::DateTime<chrono::Utc>,
  /// TODO: comment field
  timestamp: chrono::DateTime<chrono::Utc>,
  /// TODO: comment field
  fixed_size_double: f64,
  /// TODO: comment field
  var_size_double: f64,
}
'''));
  });

// end <main>
}
