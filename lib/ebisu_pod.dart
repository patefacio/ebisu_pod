library ebisu_pod.ebisu_pod;

import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('ebisu_pod');

class PodType {
  // custom <class PodType>

  PodType();
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

  String get typeName => toString();
  toString() => brCompact([
        'PodEnum($id:[${values.join(", ")}])',
        doc == null ? null : blockComment(doc)
      ]);

  // end <class PodEnum>

  Id _id;
}

class PodScalar extends PodType {
  final int value;

  // custom <class PodScalar>

  static final Double = new PodScalar._(0);
  static final Str = new PodScalar._(1);
  static final BinaryData = new PodScalar._(2);
  static final ObjectId = new PodScalar._(3);
  static final Boolean = new PodScalar._(4);
  static final Date = new PodScalar._(5);
  static final Null = new PodScalar._(6);
  static final Regex = new PodScalar._(7);
  static final Int32 = new PodScalar._(8);
  static final Int64 = new PodScalar._(9);
  static final Timestamp = new PodScalar._(10);

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

  PodScalar._(this.value);
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
  bool operator ==(PodArray other) => identical(this, other) ||
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
    if (maxLength == null) maxLength = 0;
  }

  toString() => 'PodArray(${referredType.typeName})';
  get typeName => toString();
  bool get isFixedSize => maxLength > 0;

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
  toString() => brCompact([
        'PodField($id:$podType:default=$defaultValue)',
        indentBlock(blockComment(doc))
      ]);

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

  toString() => brCompact([
        'PodObject($id)',
        indentBlock(blockComment(doc)),
        indentBlock(brCompact(fields.map((pf) => [
              '${pf.id}:${pf.podType.typeName}',
              pf.doc == null ? null : blockComment(pf.doc)
            ])))
      ]);

  bool get hasArray => fields.any((pf) => pf.podType is PodArray);

  // end <class PodObject>

  Id _id;
}

// custom <library ebisu_pod>

final Double = PodScalar.Double;
final Str = PodScalar.Str;
final BinaryData = PodScalar.BinaryData;
final ObjectId = PodScalar.ObjectId;
final Boolean = PodScalar.Boolean;
final Date = PodScalar.Date;
final Null = PodScalar.Null;
final Regex = PodScalar.Regex;
final Int32 = PodScalar.Int32;
final Int64 = PodScalar.Int64;
final Timestamp = PodScalar.Timestamp;

final doubleArray = new PodArray(Double, doc: 'Array<double>');
final stringArray = new PodArray(Str, doc: 'Array<Str>');
final binaryDataArray = new PodArray(BinaryData, doc: 'Array<BinaryData>');
final objectIdArray = new PodArray(ObjectId, doc: 'Array<ObjectId>');
final booleanArray = new PodArray(Boolean, doc: 'Array<Boolean>');
final dateArray = new PodArray(Date, doc: 'Array<Date>');
final nullArray = new PodArray(Null, doc: 'Array<Null>');
final regexArray = new PodArray(Regex, doc: 'Array<Regex>');
final int32Array = new PodArray(Int32, doc: 'Array<Int32>');
final int64Array = new PodArray(Int64, doc: 'Array<Int64>');
final timestampArray = new PodArray(Timestamp, doc: 'Array<Timestamp>');

PodEnum enum_(id, [values]) => new PodEnum(makeId(id), values);

PodField field(id, [podType]) => new PodField(makeId(id), podType == null? Str : podType);

PodObject object(id, [fields]) => new PodObject(makeId(id), fields);

PodArray array(dynamic referredType, {String doc, int maxLength}) => referredType
    is PodType
    ? new PodArray(referredType, doc: doc, maxLength: maxLength)
    : referredType is PodScalarType
        ? new PodArray(new PodScalar(referredType),
            doc: doc, maxLength: maxLength)
        : throw 'array(...) requires PodType or PodScalarType: $referredType';

PodField arrayField(id, referredType) => field(id, array(referredType));

PodFixedStr fixedStr(int maxLength) => new PodFixedStr(maxLength);

// end <library ebisu_pod>
