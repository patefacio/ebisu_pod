library ebisu_pod.test_pod_cpp;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('test_pod_cpp');

// custom <library test_pod_cpp>
// end <library test_pod_cpp>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>
// end <main>
}
