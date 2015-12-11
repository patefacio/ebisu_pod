library ebisu_pod.test_package;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import '../lib/ebisu_pod.dart';
import 'package:ebisu/ebisu.dart';

// end <additional imports>

final _logger = new Logger('test_package');

// custom <library test_package>
// end <library test_package>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

    group('package naming', () {
    test(':from string', () {
      expect(new PackageName('this.is.a.test').path,
          [makeId('this'), makeId('is'), makeId('a'), makeId('test')]);
    });

    test(':from list of Id', () {
      expect(
          new PackageName(
              [makeId('this'), makeId('is'), makeId('a'), makeId('test')]).path,
          [makeId('this'), makeId('is'), makeId('a'), makeId('test')]);
    });

    test(':from list of String', () {
      expect(new PackageName(['this', 'is', 'a', 'test']).path,
          [makeId('this'), makeId('is'), makeId('a'), makeId('test')]);
    });
  });

  test('pod package', () {
    final podPackage = new PodPackage('p')
      ..namedTypes = [
        enum_('color', ['red', 'white', 'blue']),
        enum_('usa', ['red', 'white', 'blue']),
        object('x', [field('a'), field('b', Double), field('c')]),
        object('y', [field('a'), field('b', Double), field('c')]),
      ];

    expect(podPackage.allTypes.first is PodEnum, true);
    expect(podPackage.allTypes.first.typeName, 'color');
    expect(podPackage.allTypes.last.typeName, 'y');
    expect(podPackage.allTypes.last.fields.first.name, 'a');
    expect(podPackage.allTypes.last.fields.first.podType, Str);
    expect(podPackage.allTypes.last.fields.first.typeName, 'str');

    expect(podPackage.allTypes.last.fields[1].name, 'b');
    expect(podPackage.allTypes.last.fields[1].podType, Double);
    expect(podPackage.allTypes.last.fields[1].typeName, 'double');
  });


// end <main>
}
