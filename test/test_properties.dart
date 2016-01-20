library ebisu_pod.test_properties;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_pod/ebisu_pod.dart';

// end <additional imports>

final _logger = new Logger('test_properties');

// custom <library test_properties>

enum Color { red, white, blue }

// end <library test_properties>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  final fieldProperty = defineFieldProperty(
      'serializable', 'indicates type is serializable',
      isValueValidPredicate: (Color value) => true);

  final udtProperty = defineUdtProperty(
      'serializable', 'indicates type is serializable',
      isValueValidPredicate: (Color value) => true);

  final packageProperty = definePackageProperty(
      'serializable', 'indicates type is serializable',
      isValueValidPredicate: (Color value) => true);

  group('user defined type properties', () {
    test('basic setProperty on UDT', () {
      final t = object('o')..setProperty(udtProperty, Color.blue);
      expect(t.getPropertyValue('serializable'), Color.blue);
    });

    test('setProperty throws on type mismatch', () {
      expect(() => object('o')..setProperty(fieldProperty, Color.blue),
          throwsArgumentError);
    });
  });

  group('field type properties', () {
    test('basic setProperty on field', () {
      final t = field('f', Str)..setProperty(fieldProperty, Color.blue);
      expect(t.getPropertyValue('serializable'), Color.blue);
    });

    test('setProperty throws on type mismatch', () {
      expect(() => field('o', Str)..setProperty(udtProperty, Color.blue),
          throwsArgumentError);
    });
  });

  group('package properties', () {
    test('basic setProperty on package', () {
      final t = package('p')..setProperty(packageProperty, Color.blue);
      expect(t.getPropertyValue('serializable'), Color.blue);
    });

    test('setProperty throws on type mismatch', () {
      expect(() => package('p')..setProperty(udtProperty, Color.blue),
          throwsArgumentError);
    });
  });

  group('properties and noSuchMethod', () {
    test('catches property get', () {
      final t = package('p')..setProperty(packageProperty, Color.blue);
      expect(t.getPropertyValue('serializable'), Color.blue);
      print('Found prop: ${t.serializable.value}');
    });
  });

// end <main>
}
