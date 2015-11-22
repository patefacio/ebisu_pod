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

  print(address);

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
