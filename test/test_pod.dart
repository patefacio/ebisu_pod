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
    expect(field('age', Int32), field('age', Int32));
  });

  test('fields carry type info', () {
    final e = enum_('color', ['red', 'white', 'blue']);
    expect(field('field', e).podType is PodEnum, true);
    expect(field('field', Double).podType, Double);
    expect(field('field', Str).podType, Str);
    expect(field('field', BinaryData).podType, BinaryData);
    expect(field('field', ObjectId).podType, ObjectId);
    expect(field('field', Boolean).podType, Boolean);
    expect(field('field', Date).podType, Date);
    expect(field('field', Null).podType, Null);
    expect(field('field', Regex).podType, Regex);
    expect(field('field', Int32).podType, Int32);
    expect(field('field', Int64).podType, Int64);
    expect(field('field', Timestamp).podType, Timestamp);

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

    expect(field('field', fixedStr(32)).podType, fixedStr(32));
  });

  test('isFixedSize tracks size recursively', () {
    [Double, ObjectId, Boolean, Date, Null, Regex, Int32, Int64, Timestamp]
        .forEach((var t) {
      expect(t.isFixedSize, true);

      final o = object('x')..fields = [
        field('x', t),
      ];
      expect(o.isFixedSize, true);
      final outer = object('y')..fields = [
        field('x', o)
      ];
      final outerOuter = object('z')..fields = [
        field('y', outer)
      ];
      expect(outerOuter.isFixedSize, true);
    });

    [Str, BinaryData].forEach((var t) {
      expect(t.isFixedSize, false);
      var o = object('x')..fields = [
        field('x', t),
      ];
      expect(o.isFixedSize, false);
      o = object('x')..fields = [
        field('x_arr', array(t)),
      ];
      expect(o.isFixedSize, false);

      final outer = object('y')..fields = [
        field('x', o)
      ];
      final outerOuter = object('z')..fields = [
        field('y', outer)
      ];
      expect(outerOuter.isFixedSize, false);
    });
  });

  final address = object('address')
    ..fields = [
      field('number', Int32),
      field('street', Str),
      field('zipcode', Str),
      field('state', Str),
    ];

  test('basic object has fields', () {
    expect(address.fields.length, 4);
    expect(address.fields.first, field('number', Int32));
    expect(address.fields.last, field('state', Str));
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
    final f = field('behavior', Str)..defaultValue = 'good';
    expect(f.defaultValue, 'good');
  });

  test('default field type is String', () {
    expect(field('behavior').podType, Str);
  });

  test('pod types can be self referential', () {
    final o = object('o');
    o.fields.add(field('children', array(o)));
    expect(o.fields.first.podType is PodArray, true);
    expect(o.fields.first.podType.referredType, o);
  });

// end <main>
}
