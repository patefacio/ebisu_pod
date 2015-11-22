library ebisu_pod.pod;

import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('pod');

class Foo implements Comparable<Foo> {
  static const A = const Foo._(0);
  static const B = const Foo._(1);

  static get values => [A, B];

  final int value;

  int get hashCode => value;

  const Foo._(this.value);

  copy() => this;

  int compareTo(Foo other) => value.compareTo(other.value);

  String toString() {
    switch (this) {
      case A:
        return "A";
      case B:
        return "B";
    }
    return null;
  }

  static Foo fromString(String s) {
    if (s == null) return null;
    switch (s) {
      case "A":
        return A;
      case "B":
        return B;
      default:
        return null;
    }
  }
}

class PodType {
  // custom <class PodType>

  const PodType();
  get isScalar => this is PodScalar;
  get isArray => this is PodArray;
  get isObject => this is PodObject;
  get typeName;

  // end <class PodType>

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
  get typeName => toString();

  // end <class PodScalar>

}

class PodArray extends PodType {
  const PodArray(this.referredType);

  bool operator ==(PodArray other) =>
      identical(this, other) || referredType == other.referredType;

  int get hashCode => referredType.hashCode;

  final PodType referredType;

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
          defaultValue == other.defaultValue;

  int get hashCode => hash4(_id, isIndex, podType, defaultValue);

  Id get id => _id;

  /// If true the field is defined as index
  bool isIndex = false;
  PodType podType;
  dynamic defaultValue;

  // custom <class PodField>
  // custom <class PodField>

  PodField(this._id, [this.podType]);
  toString() => 'PodField($id:$podType)';

  // end <class PodField>

  Id _id;
}

class PodObject extends PodType {
  Id get id => _id;
  List<PodField> podFields = [];

  // custom <class PodObject>

  PodObject(this._id, [this.podFields]);

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

const doubleArray = const PodArray(podDouble);
const stringArray = const PodArray(podString);
const binaryDataArray = const PodArray(podBinaryData);
const objectIdArray = const PodArray(podObjectId);
const booleanArray = const PodArray(podBoolean);
const dateArray = const PodArray(podDate);
const nullArray = const PodArray(podNull);
const regexArray = const PodArray(podRegex);
const int32Array = const PodArray(podInt32);
const int64Array = const PodArray(podInt64);
const timestampArray = const PodArray(podTimestamp);

PodField podField(id, [podType]) => new PodField(makeId(id), podType);

PodObject podObject(id, [podFields]) => new PodObject(makeId(id), podFields);

PodArray podArray(dynamic referredType) => referredType is PodType
    ? new PodArray(referredType)
    : referredType is PodScalarType
        ? new PodArray(new PodScalar(referredType))
        : throw 'podArray(...) requires PodType or PodScalarType: $referredType';

PodField podArrayField(id, referredType) =>
    podField(id, podArray(referredType));

// end <library pod>
