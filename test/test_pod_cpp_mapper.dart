library ebisu_pod.test_pod_cpp_mapper;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_pod/example/balance_sheet.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu_pod/pod_cpp.dart';

// end <additional imports>

final _logger = new Logger('test_pod_cpp_mapper');

// custom <library test_pod_cpp_mapper>
// end <library test_pod_cpp_mapper>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  final bs = balanceSheet;
  final mapper = new PodCppMapper(balanceSheet);

  test('pod cpp mapper', () {
    final header = mapper.header;
    final holdingTypeEnum =
        header.enums.singleWhere((e) => e.id.snake == 'holding_type');
    final holdingClass =
        header.classes.singleWhere((c) => c.id.snake == 'holding');
    expect(holdingTypeEnum.values.first.id.snake, 'other');
    expect(holdingClass.members.first.id.snake, 'holding_type');
  });

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

    final pkg = new PodPackage('sample', namedTypes: [po]);
    final mapper = new PodCppMapper(pkg);
    final darkContent = darkMatter(mapper.header.contents);

    expect(
        [
          'ebisu/utils/streamers/array.hpp',
          'ebisu/utils/streamers/vector.hpp',
          'array',
          'vector'
        ].every((i) => darkContent.contains(
            darkMatter('#include "ebisu/utils/fixed_size_char_array.hpp"'))),
        true);
    expect(
        darkContent.contains(darkMatter(
            'using Str_10_t = ebisu::utils::Fixed_size_char_array<10>;')),
        true);
    expect(darkContent.contains(darkMatter('''
  char a_char {};
  double a_double {};
  Object_id object_id {};
  bool boolean {};
  boost::gregorian::date date {};
  boost::regex regex {};
  std::int8_t int8 {};
  std::int16_t int16 {};
  std::int32_t int32 {};
  std::int64_t int64 {};
  std::uint8_t uint8 {};
  std::uint16_t uint16 {};
  std::uint32_t uint32 {};
  std::uint64_t uint64 {};
  Date_time date_time {};
  Timestamp timestamp {};
  Str_10_t fixed_size_str {};
  std::array<double, 12> fixed_size_double {};
  std::vector<double> var_size_double {};
''')), true);
  });

// end <main>
}
