library ebisu_pod.test_example;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_pod/example/balance_sheet.dart';

// end <additional imports>

final _logger = new Logger('test_example');

// custom <library test_example>
// end <library test_example>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  Logger.root.level = Level.INFO;
  test('balance_sheet', () {
    print(balanceSheet);
  });

// end <main>
}
