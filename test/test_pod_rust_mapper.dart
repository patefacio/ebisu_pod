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
      field('date', Date),
      field('timestamp', Timestamp)..isOptional = true,
      // TODO: field('fixed_size_str', fixedStr(10)),
      field('fixed_size_double', array(Double, maxLength: 12)),
      field('var_size_double', array(Double)),
      // TODO: bitSetField('bs', 4, rhsPadBits: 2),
    ]);

    final pkg = new PodPackage('sample', namedTypes: [
      podPredefinedType('goo')..setProperty('rust_aliased_to', 'f64'),
      po,
      enum_('foo', ['a', 'b', 'c']),
    ]);
    final mapper = new PodRustMapper(pkg);

    expect(darkMatter(mapper.module.code), darkMatter('''
//! TODO: comment module sample

// --- module type aliases ---

pub type Goo = f64;

// --- module enum definitions ---

/// TODO: comment foo
#[derive(Debug, Clone, Copy, Eq, PartialEq, Hash, Serialize, Deserialize)]
pub enum Foo {
    /// TODO: comment a
    A,
    /// TODO: comment b
    B,
    /// TODO: comment c
    C,
}

// --- module struct definitinos ---

/// TODO: comment struct `AllTypes`
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct AllTypes {
  /// TODO: comment field
  pub a_char: char,
  /// TODO: comment field
  pub a_double: f64,
  /// TODO: comment field
  pub boolean: bool,
  /// TODO: comment field
  pub date: Date,
  /// TODO: comment field
  pub regex: regex::Regex,
  /// TODO: comment field
  pub int8: i8,
  /// TODO: comment field
  pub int16: i16,
  /// TODO: comment field
  pub int32: i32,
  /// TODO: comment field
  pub int64: i64,
  /// TODO: comment field
  pub uint8: u8,
  /// TODO: comment field
  pub uint16: u16,
  /// TODO: comment field
  pub uint32: u32,
  /// TODO: comment field
  pub uint64: u64,
  /// TODO: comment field
  pub date: Date,
  /// TODO: comment field
  pub timestamp: Option<chrono::DateTime<chrono::Utc>>,
  /// TODO: comment field
  pub fixed_size_double: [f64, 12],
  /// TODO: comment field
  pub var_size_double: Vec<f64>,
}

// --- module impl definitions ---

/// Implementation of trait `Default` for type `Foo`
impl Default<> for Foo {
  /// A trait for giving a type a useful default value.
  ///
  ///  * _return_ - The default value for the type
  ///
  fn default() -> Self {
    Foo::A
  }

  // custom <impl Default for Foo>
  // end <impl Default for Foo>
}

// custom <module sample ModuleBottom>
// end <module sample ModuleBottom>

'''));
  });

// end <main>
}
