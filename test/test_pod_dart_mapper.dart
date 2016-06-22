library ebisu_pod.test_pod_dart_mapper;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_pod/example/balance_sheet.dart';
import 'package:ebisu_pod/pod_dart.dart';
import 'package:ebisu_pod/ebisu_pod.dart';

// end <additional imports>

final Logger _logger = new Logger('test_pod_dart_mapper');

// custom <library test_pod_dart_mapper>
// end <library test_pod_dart_mapper>

void main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  final mapper = new PodDartMapper(dossier);

// end <main>
}
