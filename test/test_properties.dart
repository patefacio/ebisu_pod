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
      final t = object('o')..setProperty('serializable', Color.blue);
      expect(t.getProperty('serializable'), Color.blue);
    });
  });

  group('field type properties', () {
    test('basic setProperty on field', () {
      final t = field('f', Str)..setProperty('serializable', Color.blue);
      expect(t.getProperty('serializable'), Color.blue);
    });
  });

  group('package properties', () {
    test('basic setProperty on package', () {
      final t = package('p')..setProperty('serializable', Color.blue);
      expect(t.getProperty('serializable'), Color.blue);
    });
  });

  group('properties and noSuchMethod', () {
    test('catches property get', () {
      final t = package('p')..setProperty('serializable', Color.blue);
      expect(t.getProperty('serializable'), Color.blue);
      t.setProperty('serializable', true);
      expect(t.propertyNames, ['serializable']);
      final f = field('o', Str)..setProperty('donkeys', 'ehh-haw');
      expect(f.getProperty('donkeys'), 'ehh-haw');
    });
  });

  test('property validations', () {
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
          ..setProperty('serializable', true)
          ..setProperty('badProp', false)
      ])..setProperty('serializable', true)..setProperty('badProp', false)
    ])
      ..propertyDefinitionSets.add(pds)
      ..setProperty('serializable', true)
      ..setProperty('badProp', false);

    final errors = pkg.propertyErrors;
    expect(
        errors.contains(
            new PropertyError(PACKAGE_PROPERTY, 'my_data', 'badProp')),
        true);
    expect(errors.contains(new PropertyError(FIELD_PROPERTY, 'f1', 'badProp')),
        true);
    expect(
        errors.contains(new PropertyError(UDT_PROPERTY, 'o', 'badProp')), true);
  });

// end <main>
}
