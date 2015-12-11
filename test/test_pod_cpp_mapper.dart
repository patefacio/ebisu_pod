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
    final holdingTypeEnum = header.enums.singleWhere((e) => e.id.snake == 'holding_type');
    final holdingClass = header.classes.singleWhere((c) => c.id.snake == 'holding');
    print(holdingTypeEnum);
  });

  print(mapper.header.contents);

// end <main>
}
