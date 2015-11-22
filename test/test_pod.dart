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

  test('podFields are comparable', () {
    expect(podField('age', podInt32), podField('age', podInt32));
  });

  test('podFields carry type info', () {
    expect(podField('field', podDouble).podType, podDouble);
    expect(podField('field', podString).podType, podString);
    expect(podField('field', podBinaryData).podType, podBinaryData);
    expect(podField('field', podObjectId).podType, podObjectId);
    expect(podField('field', podBoolean).podType, podBoolean);
    expect(podField('field', podDate).podType, podDate);
    expect(podField('field', podNull).podType, podNull);
    expect(podField('field', podRegex).podType, podRegex);
    expect(podField('field', podInt32).podType, podInt32);
    expect(podField('field', podInt64).podType, podInt64);
    expect(podField('field', podTimestamp).podType, podTimestamp);

    expect(podField('field', doubleArray).podType, doubleArray);
    expect(podField('field', stringArray).podType, stringArray);
    expect(podField('field', binaryDataArray).podType, binaryDataArray);
    expect(podField('field', objectIdArray).podType, objectIdArray);
    expect(podField('field', booleanArray).podType, booleanArray);
    expect(podField('field', dateArray).podType, dateArray);
    expect(podField('field', nullArray).podType, nullArray);
    expect(podField('field', regexArray).podType, regexArray);
    expect(podField('field', int32Array).podType, int32Array);
    expect(podField('field', int64Array).podType, int64Array);
    expect(podField('field', timestampArray).podType, timestampArray);
  });

  final address = podObject('address')
    ..podFields = [
      podField('number', podInt32),
      podField('street', podString),
      podField('zipcode', podString),
      podField('state', podString),
    ];

  test('basic object has fields', () {
    expect(address.podFields.length, 4);
    expect(address.podFields.first, podField('number', podInt32));
    expect(address.podFields.last, podField('state', podString));
  });

  test('fields can be PodScalar, PodArray or PodObject', () {
    final referred = podObject('referred');
    final obj = podObject('obj', [
      podField('scalar'),
      podField('array', int32Array),
      podField('object', referred)
    ]);
    expect(obj.podFields.first.podType is PodScalar, true);
    expect(obj.podFields[1].podType is PodArray, true);
    expect(obj.podFields.last.podType is PodObject, true);
  });

  test('fields may have defaults', () {
    final field = podField('behavior', podString)..defaultValue = 'good';
    expect(field.defaultValue, 'good');
  });

  test('default field type is podString', () {
    expect(podField('behavior').podType, podString);
  });

  test('pod types can be self referential', () {
    final o = podObject('o');
    o.podFields.add(podField('children', podArray(o)));
    expect(o.podFields.first.podType is PodArray, true);
    expect(o.podFields.first.podType.referredType, o);
  });

// end <main>
}
