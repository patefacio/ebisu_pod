library ebisu_pod.test_pod;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import '../lib/pod.dart';

// end <additional imports>

final _logger = new Logger('test_pod');

// custom <library test_pod>
// end <library test_pod>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  test('fields are comparable', () {
    expect(field('age', podInt32), field('age', podInt32));
  });

  test('fields carry type info', () {
    final e = enum_('color', ['red', 'white', 'blue']);
    expect(field('field', e).podType is PodEnum, true);
    expect(field('field', podDouble).podType, podDouble);
    expect(field('field', podString).podType, podString);
    expect(field('field', podBinaryData).podType, podBinaryData);
    expect(field('field', podObjectId).podType, podObjectId);
    expect(field('field', podBoolean).podType, podBoolean);
    expect(field('field', podDate).podType, podDate);
    expect(field('field', podNull).podType, podNull);
    expect(field('field', podRegex).podType, podRegex);
    expect(field('field', podInt32).podType, podInt32);
    expect(field('field', podInt64).podType, podInt64);
    expect(field('field', podTimestamp).podType, podTimestamp);

    expect(field('field', doubleArray).podType, doubleArray);
    expect(field('field', stringArray).podType, stringArray);
    expect(field('field', binaryDataArray).podType, binaryDataArray);
    expect(field('field', objectIdArray).podType, objectIdArray);
    expect(field('field', booleanArray).podType, booleanArray);
    expect(field('field', dateArray).podType, dateArray);
    expect(field('field', nullArray).podType, nullArray);
    expect(field('field', regexArray).podType, regexArray);
    expect(field('field', int32Array).podType, int32Array);
    expect(field('field', int64Array).podType, int64Array);
    expect(field('field', timestampArray).podType, timestampArray);

    expect(
        field('field', fixedSizeString(32)).podType, fixedSizeString(32));
  });

  final address = object('address')
    ..fields = [
      field('number', podInt32),
      field('street', podString),
      field('zipcode', podString),
      field('state', podString),
    ];

  test('basic object has fields', () {
    expect(address.fields.length, 4);
    expect(address.fields.first, field('number', podInt32));
    expect(address.fields.last, field('state', podString));
  });

  test('fields can be PodScalar, PodArray or PodObject', () {
    final referred = object('referred');
    final obj = object('obj', [
      field('scalar'),
      field('array', int32Array),
      field('object', referred)
    ]);
    expect(obj.fields.first.podType is PodScalar, true);
    expect(obj.fields[1].podType is PodArray, true);
    expect(obj.fields.last.podType is PodObject, true);
  });

  test('fields may have defaults', () {
    final f = field('behavior', podString)..defaultValue = 'good';
    expect(f.defaultValue, 'good');
  });

  test('default field type is podString', () {
    expect(field('behavior').podType, podString);
  });

  test('pod types can be self referential', () {
    final o = object('o');
    o.fields.add(field('children', array(o)));
    expect(o.fields.first.podType is PodArray, true);
    expect(o.fields.first.podType.referredType, o);
  });

// end <main>
}
