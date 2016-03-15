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

  group('user defined type properties', () {
    test('basic setProperty on UDT', () {
      final t = object('o')..serializable = Color.blue;
      expect(t.serializable, Color.blue);
    });
  });

  group('field type properties', () {
    test('basic setProperty on field', () {
      final t = field('f', Str)..serializable = Color.blue;
      expect(t.serializable, Color.blue);
    });
  });

  group('package properties', () {
    test('basic setProperty on package', () {
      final t = package('p')..serializable = Color.blue;
      expect(t.serializable, Color.blue);
    });
  });

  group('properties and noSuchMethod', () {
    test('catches property get', () {
      final t = package('p')..serializable = Color.blue;
      expect(t.serializable, Color.blue);
      t.serializable = true;
      expect(t.propertyNames, ['serializable']);
      final f = field('o', Str)..donkeys = 'ehh-haw';
      expect(f.donkeys, 'ehh-haw');
    });
  });

  group('property validations', () {
    final fieldProperty = defineFieldProperty(
        'serializable', 'indicates type is serializable',
        isValueValidPredicate: (Color value) => true);

    final udtProperty = defineUdtProperty(
        'serializable', 'indicates type is serializable',
        isValueValidPredicate: (Color value) => true);

    final packageProperty = definePackageProperty(
        'serializable', 'indicates type is serializable',
        isValueValidPredicate: (Color value) => true);

    var pds = new PropertyDefinitionSet('serializable_props')
      ..fieldPropertyDefinitions.add(fieldProperty)
      ..udtPropertyDefinitions.add(udtProperty)
      ..packagePropertyDefinitions.add(packageProperty);

    final pkg = package('my_data', namedTypes: [
      object('o', [
        field('f1', Int32)
          ..serializable = true
          ..badProp = false
      ])
        ..serializable = true
        ..badProp = false
    ])
      ..propertyDefinitionSets.add(pds)
      ..serializable = true
      ..badProp = false;

    print(pkg.propertyErrors);
  });

// end <main>
}
