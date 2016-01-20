library ebisu_pod.test_pod_cpp_mapper;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

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
      field('char', Char),
      field('double', Double),
      field('object_id', ObjectId),
      field('boolean', Boolean),
      field('date', Date),
      field('null', Null),
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
      field('timestamp', Timestamp)
    ]);

    final pkg = new PodPackage('sample', namedTypes: [po]);
    final mapper = new PodCppMapper(pkg);
    print(mapper.header.contents);
  });

// end <main>
}
