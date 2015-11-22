library ebisu_pod.test_pod;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('test_pod');

// custom <library test_pod>
// end <library test_pod>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  final address = podObject('address')
    ..podFields = [
      podField('street', bsonString),
      podField('zipcode', bsonString),
      podField('state', bsonString),
    ];

  final person = podObject('person');

  person
    ..podFields = [
      podField('name', bsonString),
      podField('age', bsonInt32)..defaultValue = 32,
      podField('birth_date', bsonDate),
      podField('address', address)..defaultValue = '"foo", "bar", "goo"',
      podArrayField('children', person),
      podArrayField('pet_names', bsonString),
      podArrayField('pet_ages', bsonInt32),
    ];

  print(person);

// end <main>
}
