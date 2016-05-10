library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import 'package:hop_docgen/hop_docgen.dart';
import 'package:path/path.dart' as path;
import '../test/runner.dart' as runner;

void main(List<String> args) {
  Directory.current = path.dirname(path.dirname(Platform.script.toFilePath()));

  addTask('analyze_lib', createAnalyzerTask(_getLibs));
  //TODO: Figure this out: addTask('docs', createDocGenTask(_getLibs));
  addTask(
      'analyze_test',
      createAnalyzerTask([
        "test/test_pod.dart",
        "test/test_package.dart",
        "test/test_example.dart",
        "test/test_max_length.dart",
        "test/test_bitset.dart",
        "test/test_pod_cpp_mapper.dart",
        "test/test_properties.dart"
      ]));

  runHop(args);
}

Future<List<String>> _getLibs() {
  return new Directory('lib')
      .list()
      .where((FileSystemEntity fse) => fse is File)
      .map((File file) => file.path)
      .toList();
}
