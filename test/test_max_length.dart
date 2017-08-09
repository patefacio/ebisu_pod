library ebisu_pod.test_max_length;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_pod/ebisu_pod.dart';

// end <additional imports>

final Logger _logger = new Logger('test_max_length');

// custom <library test_max_length>
// end <library test_max_length>

void main([List<String> args]) {
  if (args?.isEmpty ?? false) {
    Logger.root.onRecord.listen(
        (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
    Logger.root.level = Level.OFF;
  }
// custom <main>

  group('max length', () {
    pkg(arr) => package('test', namedTypes: [
          object('o', [field('f', arr)])
        ]);

    test('on string with int', () {
      final arr = array(Int32);
      final p = pkg(arr);
      arr.maxLength = 3;
      expect(arr.isFixedSizeArray, true);
    });

    test('on string with PodConstant', () {
      final pc = constant('p_c', Int8, 3);
      final arr = array(Int32, maxLength: pc);
    });

    test('on array with int', () {});

    test('on array with PodConstant', () {});

    test('on string with double', () {
      final arr = array(Int32);
      final p = pkg(arr);
    });
  });

// end <main>
}
