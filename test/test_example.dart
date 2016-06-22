library ebisu_pod.test_example;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_pod/example/balance_sheet.dart';
import 'package:ebisu_pod/ebisu_pod.dart';

// end <additional imports>

final Logger _logger = new Logger('test_example');

// custom <library test_example>
// end <library test_example>

void main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  Logger.root.level = Level.OFF;
  test('balance_sheet', () {
    expect(balanceSheet.getType('holding_type') is PodEnum, true);
    expect(balanceSheet.getType('date').typeName, 'date');
    expect(balanceSheet.getType('holding').typeName, 'holding');
    expect(balanceSheet.getType('holding').getField('holding_type').typeName,
        'holding_type');
  });

// end <main>
}
