library ebisu_pod.test_package;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import '../lib/ebisu_pod.dart';
import 'package:ebisu/ebisu.dart';

// end <additional imports>

final Logger _logger = new Logger('test_package');

// custom <library test_package>
// end <library test_package>

void main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  Logger.root.level = Level.INFO;

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

  group('pod package', () {
    test('enums and objects only', () {
      var e, o;
      final p = package('p', namedTypes: [
        (e = enum_('color', ['red', 'white', 'blue'])),
        (o = object('z', [field('z')])),
      ]);
      expect(p.getType('color'), e);
      expect(p.getType('z'), o);
    });
  });

  test('pod package', () {
    final podConstants = [constant('max_size', Int32, 42),];

    final namedTypes = [
      enum_('color', ['red', 'white', 'blue']),
      enum_('usa', ['red', 'white', 'blue']),
      object('z', [field('x', 'x')]),
      object('x', [field('a'), field('b', Double), field('c')]),
      object('a', [
        field('b', object('ax', [field('c')]))
      ]),
      object('y', [field('a'), field('b', Double), field('c')]),
    ];

    final podPackage =
        new PodPackage('p', namedTypes: namedTypes, podConstants: podConstants);

    expect(podPackage.allTypes.first is PodEnum, true);
    expect(podPackage.allTypes.first.typeName, 'color');
    expect(podPackage.allTypes.last.typeName, 'y');
    expect(podPackage.allTypes.last.fields.first.name, 'a');
    expect(podPackage.allTypes.last.fields.first.podType, Str);
    expect(podPackage.allTypes.last.fields.first.typeName, 'str');

    expect(podPackage.allTypes.last.fields[1].name, 'b');
    expect(podPackage.allTypes.last.fields[1].podType, Double);
    expect(podPackage.allTypes.last.fields[1].typeName, 'double');

    expect(podPackage.getType('usa'), enum_('usa', ['red', 'white', 'blue']));
  });

  test('package import', () {
    final a = package('a', namedTypes: [
      enum_('color', ['red', 'white', 'blue'])
    ]);
    final b = package('b', imports: [
      a
    ], namedTypes: [
      object('b', [field('color', 'a.color')])
    ]);

    final c1 = a.getType('color');
    final c2 = b.getType('b').getField('color');
    final x = b.getType('b').getField('color').podType;
    expect(b.getFieldType('b', 'color'), a.getType('color'));
  });

// end <main>
}
