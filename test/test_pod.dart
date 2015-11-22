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
      podField('street', podString),
      podField('zipcode', podString),
      podField('state', podString),
    ];

  test('basic object has fields', () {
    expect(address.podFields.length, 3);
    expect(address.podFields.first, podField('street', podString));
  });

  final person = podObject('person');

  person
    ..podFields = [
      podField('name', podString),
      podField('age', podInt32)..defaultValue = 32,
      podField('birth_date', podDate),
      podField('address', address)..defaultValue = '"foo", "bar", "goo"',
      podArrayField('children', person),
      podArrayField('pet_names', podString),
      podArrayField('pet_ages', podInt32),
    ];

  print(person);

// end <main>
}
