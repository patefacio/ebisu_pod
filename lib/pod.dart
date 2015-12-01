library ebisu_pod.pod;

import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('pod');

class PodType {
  // custom <class PodType>

  const PodType();
  get isScalar => this is PodScalar;
  get isArray => this is PodArray;
  get isObject => this is PodObject;

  String get doc;
  String get typeName;

  // end <class PodType>

}

class PodEnum extends PodType {
  Id get id => _id;
  List<String> values = [];

  /// Documentation for the enum
  String doc;

  // custom <class PodEnum>

  PodEnum(this._id, [this.values]) {
    if (values == null) {
      values = [];
    }
  }

  // end <class PodEnum>

  Id _id;
}

class PodScalar extends PodType {
  final int value;

  // custom <class PodScalar>

  static const podDouble = const PodScalar._(0);
  static const podString = const PodScalar._(1);
  static const podBinaryData = const PodScalar._(2);
  static const podObjectId = const PodScalar._(3);
  static const podBoolean = const PodScalar._(4);
  static const podDate = const PodScalar._(5);
  static const podNull = const PodScalar._(6);
  static const podRegex = const PodScalar._(7);
  static const podInt32 = const PodScalar._(8);
  static const podInt64 = const PodScalar._(9);
  static const podTimestamp = const PodScalar._(10);

  static get values => [
        podDouble,
        podString,
        podBinaryData,
        podObjectId,
        podBoolean,
        podDate,
        podNull,
        podRegex,
        podInt32,
        podInt64,
        podTimestamp
      ];

  String toString() {
    switch (this) {
      case podDouble:
        return 'podDouble';
      case podString:
        return 'podString';
      case podBinaryData:
        return 'podBinaryData';
      case podObjectId:
        return 'podObjectId';
      case podBoolean:
        return 'podBoolean';
      case podDate:
        return 'podDate';
      case podNull:
        return 'podNull';
      case podRegex:
        return 'podRegex';
      case podInt32:
        return 'podInt32';
      case podInt64:
        return 'podInt64';
      case podTimestamp:
        return 'podTimestamp';
    }
  }

  const PodScalar._(this.value);
  String get doc => 'builtin ${this}';
  get typeName => toString();

  // end <class PodScalar>

}

class PodArray extends PodType {
  PodArray(this.referredType, [this.doc]);

  bool operator ==(PodArray other) => identical(this, other) ||
      referredType == other.referredType && doc == other.doc;

  int get hashCode => hash2(referredType, doc);

  final PodType referredType;

  /// Documentation for the array
  final String doc;

  // custom <class PodArray>

  toString() => 'PodArray(${referredType.typeName})';
  get typeName => toString();

  // end <class PodArray>

}

class PodField {
  bool operator ==(PodField other) => identical(this, other) ||
      _id == other._id &&
          isIndex == other.isIndex &&
          podType == other.podType &&
          defaultValue == other.defaultValue &&
          doc == other.doc;

  int get hashCode => hashObjects([_id, isIndex, podType, defaultValue, doc]);

  Id get id => _id;

  /// If true the field is defined as index
  bool isIndex = false;
  PodType podType;
  dynamic defaultValue;

  /// Documentation for the field
  String doc;

  // custom <class PodField>
  // custom <class PodField>

  PodField(this._id, [this.podType]);
  toString() => 'PodField($id:$podType:default=$defaultValue)';

  // end <class PodField>

  Id _id;
}

class PodObject extends PodType {
  Id get id => _id;
  List<PodField> podFields = [];

  /// Documentation for the object
  String doc;

  // custom <class PodObject>

  PodObject(this._id, [this.podFields]) {
    if (podFields == null) {
      podFields = [];
    }
  }

  get typeName => 'PodObject($_id)';

  toString() {
    print('to string on object $id');

    return brCompact([
      'PodObject($id)',
      indentBlock(
          brCompact(podFields.map((pf) => '${pf.id}:${pf.podType.typeName}')))
    ]);
  }

  bool get hasArray => podFields.any((pf) => pf.podType is PodArray);

  // end <class PodObject>

  Id _id;
}

// custom <library pod>

const podDouble = PodScalar.podDouble;
const podString = PodScalar.podString;
const podBinaryData = PodScalar.podBinaryData;
const podObjectId = PodScalar.podObjectId;
const podBoolean = PodScalar.podBoolean;
const podDate = PodScalar.podDate;
const podNull = PodScalar.podNull;
const podRegex = PodScalar.podRegex;
const podInt32 = PodScalar.podInt32;
const podInt64 = PodScalar.podInt64;
const podTimestamp = PodScalar.podTimestamp;

final doubleArray = new PodArray(podDouble, 'Array<double>');
final stringArray = new PodArray(podString, 'Array<String>');
final binaryDataArray = new PodArray(podBinaryData, 'Array<BinaryData>');
final objectIdArray = new PodArray(podObjectId, 'Array<ObjectId>');
final booleanArray = new PodArray(podBoolean, 'Array<Boolean>');
final dateArray = new PodArray(podDate, 'Array<Date>');
final nullArray = new PodArray(podNull, 'Array<Null>');
final regexArray = new PodArray(podRegex, 'Array<Regex>');
final int32Array = new PodArray(podInt32, 'Array<Int32>');
final int64Array = new PodArray(podInt64, 'Array<Int64>');
final timestampArray = new PodArray(podTimestamp, 'Array<Timestamp>');

PodEnum podEnum(id, [values]) => new PodEnum(makeId(id), values);

PodField podField(id, [podType = podString]) =>
    new PodField(makeId(id), podType);

PodObject podObject(id, [podFields]) => new PodObject(makeId(id), podFields);

PodArray podArray(dynamic referredType) => referredType is PodType
    ? new PodArray(referredType)
    : referredType is PodScalarType
        ? new PodArray(new PodScalar(referredType))
        : throw 'podArray(...) requires PodType or PodScalarType: $referredType';

PodField podArrayField(id, referredType) =>
    podField(id, podArray(referredType));

// end <library pod>
