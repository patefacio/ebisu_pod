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
  bool get isFixedSize;

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

  static const Double = const PodScalar._(0);
  static const Str = const PodScalar._(1);
  static const BinaryData = const PodScalar._(2);
  static const ObjectId = const PodScalar._(3);
  static const Boolean = const PodScalar._(4);
  static const Date = const PodScalar._(5);
  static const Null = const PodScalar._(6);
  static const Regex = const PodScalar._(7);
  static const Int32 = const PodScalar._(8);
  static const Int64 = const PodScalar._(9);
  static const Timestamp = const PodScalar._(10);

  static get values => [
        Double,
        Str,
        BinaryData,
        ObjectId,
        Boolean,
        Date,
        Null,
        Regex,
        Int32,
        Int64,
        Timestamp
      ];

  String toString() {
    switch (this) {
      case Double:
        return 'Double';
      case Str:
        return 'Str';
      case BinaryData:
        return 'BinaryData';
      case ObjectId:
        return 'ObjectId';
      case Boolean:
        return 'Boolean';
      case Date:
        return 'Date';
      case Null:
        return 'Null';
      case Regex:
        return 'Regex';
      case Int32:
        return 'Int32';
      case Int64:
        return 'Int64';
      case Timestamp:
        return 'Timestamp';
    }
  }

  bool get isFixedSize => this != Str && this != BinaryData;

  const PodScalar._(this.value);
  String get doc => 'builtin ${this}';
  get typeName => toString();

  // end <class PodScalar>

}


/// Used to store strings that have a capped size.
///
/// The primary purpose for modeling data as fixed size string over the
/// more general scalar string type is so code generators may optimize for
/// speed by allocating space for strings inline.
class PodFixedStr extends PodType {

  /// Documentation for fixed size string
  String doc;
  /// If non-0 indicates length capped to [max_length]
  int maxLength = 0;

  // custom <class PodFixedStr>

  factory PodFixedStr(int maxLength, [doc]) => _typeCache.putIfAbsent(
      maxLength, () => new PodFixedStr._(maxLength, doc));

  PodFixedStr._(this.maxLength, [this.doc]);

  toString() => 'PodFixedStr($maxLength)';
  get typeName => toString();
  bool get isFixedSize => true;

  // end <class PodFixedStr>

  /// Cache of all fixed size strings
  static Map<int, PodFixedStr> _typeCache = new Map<int, PodFixedStr>();

}


class PodArray extends PodType {

  bool operator==(PodArray other) =>
    identical(this, other) ||
    referredType == other.referredType &&
    doc == other.doc &&
    maxLength == other.maxLength;

  int get hashCode => hash3(referredType, doc, maxLength);

  PodType referredType;
  /// Documentation for the array
  String doc;
  /// If non-0 indicates length capped to [max_length]
  int maxLength = 0;

  // custom <class PodArray>

  PodArray(this.referredType, {this.doc, this.maxLength}) {
    if(maxLength == null) maxLength = 0;
  }

  toString() => 'PodArray(${referredType.typeName})';
  get typeName => toString();
  bool get isFixedSize => maxLength > 0;

  // end <class PodArray>

}


class PodField {

  bool operator==(PodField other) =>
    identical(this, other) ||
    _id == other._id &&
    isIndex == other.isIndex &&
    podType == other.podType &&
    defaultValue == other.defaultValue &&
    doc == other.doc;

  int get hashCode => hashObjects([
    _id,
    isIndex,
    podType,
    defaultValue,
    doc]);

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

  bool get isFixedSize => podType.isFixedSize;

  // end <class PodField>

  Id _id;

}


class PodObject extends PodType {

  Id get id => _id;
  List<PodField> fields = [];
  /// Documentation for the object
  String doc;

  // custom <class PodObject>

  PodObject(this._id, [this.fields]) {
    if (fields == null) {
      fields = [];
    }
  }

  get typeName => 'PodObject($_id)';

  bool get isFixedSize => fields.every((f) => f.isFixedSize);

  toString() {
    print('to string on object $id');

    return brCompact([
      'PodObject($id)',
      indentBlock(
          brCompact(fields.map((pf) => '${pf.id}:${pf.podType.typeName}')))
    ]);
  }

  bool get hasArray => fields.any((pf) => pf.podType is PodArray);

  // end <class PodObject>

  Id _id;

}

// custom <library pod>

const Double = PodScalar.Double;
const Str = PodScalar.Str;
const BinaryData = PodScalar.BinaryData;
const ObjectId = PodScalar.ObjectId;
const Boolean = PodScalar.Boolean;
const Date = PodScalar.Date;
const Null = PodScalar.Null;
const Regex = PodScalar.Regex;
const Int32 = PodScalar.Int32;
const Int64 = PodScalar.Int64;
const Timestamp = PodScalar.Timestamp;

final doubleArray = new PodArray(Double, doc:'Array<double>');
final stringArray = new PodArray(Str, doc:'Array<Str>');
final binaryDataArray = new PodArray(BinaryData, doc:'Array<BinaryData>');
final objectIdArray = new PodArray(ObjectId, doc:'Array<ObjectId>');
final booleanArray = new PodArray(Boolean, doc:'Array<Boolean>');
final dateArray = new PodArray(Date, doc:'Array<Date>');
final nullArray = new PodArray(Null, doc:'Array<Null>');
final regexArray = new PodArray(Regex, doc:'Array<Regex>');
final int32Array = new PodArray(Int32, doc:'Array<Int32>');
final int64Array = new PodArray(Int64, doc:'Array<Int64>');
final timestampArray = new PodArray(Timestamp, doc:'Array<Timestamp>');

PodEnum enum_(id, [values]) => new PodEnum(makeId(id), values);

PodField field(id, [podType = Str]) => new PodField(makeId(id), podType);

PodObject object(id, [fields]) => new PodObject(makeId(id), fields);

PodArray array(dynamic referredType, {String doc, int maxLength}) => referredType is PodType
  ? new PodArray(referredType, doc: doc, maxLength: maxLength)
    : referredType is PodScalarType
  ? new PodArray(new PodScalar(referredType), doc: doc, maxLength: maxLength)
        : throw 'podArray(...) requires PodType or PodScalarType: $referredType';

PodField arrayField(id, referredType) => podField(id, podArray(referredType));

PodFixedStr fixedStr(int maxLength) => new PodFixedStr(maxLength);

// end <library pod>
