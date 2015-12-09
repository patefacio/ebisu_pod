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

class FixedSizeType extends PodType {
  // custom <class FixedSizeType>
  // end <class FixedSizeType>

  bool get isFixedSize => true;
}

class VariableSizeType extends PodType {
  VariableSizeType(this.maxLength);

  /// If non-0 indicates length capped to [max_length]
  int maxLength;

  // custom <class VariableSizeType>
  // end <class VariableSizeType>

  bool get isFixedSize => maxLength != null;
}

/// Used to define string types, which may have a fixed type.
///
/// The primary purpose for modeling data as fixed size strings over the
/// more general string type is so code generators may optimize for speed
/// by allocating space for strings inline.
class StrType extends VariableSizeType {
  /// Documentation for fixed size string
  String doc;

  // custom <class StrType>

  factory StrType([maxLength, doc]) =>
      _typeCache.putIfAbsent(maxLength, () => new StrType._(maxLength, doc));

  StrType._([maxLength, this.doc]) : super(maxLength);
  toString() => 'StrType($maxLength)';
  get typeName => toString();

  // end <class StrType>

  /// Cache of all fixed size strings
  static Map<int, Str> _typeCache = new Map<int, Str>();
}

/// Stores binary data as array of bytes
class BinaryDataType extends VariableSizeType {
  /// Documentation for the binary data type
  String doc;

  // custom <class BinaryDataType>

  factory BinaryDataType([maxLength, doc]) => _typeCache.putIfAbsent(
      maxLength, () => new BinaryDataType._(maxLength, doc));

  BinaryDataType._([maxLength, this.doc]) : super(maxLength);
  toString() => 'BinaryDataType($maxLength)';
  get typeName => toString();

  // end <class BinaryDataType>

  /// Cache of all fixed size BinaryData types
  static Map<int, BinaryData> _typeCache = new Map<int, BinaryData>();
}

class PodArray extends VariableSizeType {
  bool operator ==(PodArray other) => identical(this, other) ||
      referredType == other.referredType && doc == other.doc;

  int get hashCode => hash2(referredType, doc);

  PodType referredType;

  /// Documentation for the array
  String doc;

  // custom <class PodArray>

  PodArray(this.referredType, {this.doc, maxLength}) : super(maxLength) {
    if (this.maxLength == null) this.maxLength = 0;
  }

  toString() => 'PodArray(${referredType.typeName})';
  get typeName => toString();
  bool get isFixedSize => maxLength > 0;

  // end <class PodArray>

}

/// Combination of owning package name and name of a type within it
class PodTypeRef {
  PackageName packageName;
  Id typeName;

  // custom <class PodTypeRef>
  // end <class PodTypeRef>

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

class PodAlias {
  /// Alias name for referenced type
  Id id;
  PodTypeRef podTypeRef;

  // custom <class PodAlias>
  // end <class PodAlias>

}

/// Package names are effectively a list of Id isntances.
///
/// They can be constructed from and represented by the common dotted form:
///
///    [ id('dossier'), id('common') ] => 'dossier.common'
///
///    [ id('dossier'), id('balance_sheet') ] => 'dossier.balance_sheet'
class PackageName {
  Lsit<Id> identity = [];

  // custom <class PackageName>
  // end <class PackageName>

}

/// Package structure to support organization of pod definitions
class PodPackage extends Entity {
  /// Name of package
  PackageName name;

  /// Packages required by (ie containing referenced types) this package
  List<Package> imports = [];

  /// The named and therefore referencable types within the package
  Map<String, PodType> types = {};

  // custom <class PodPackage>
  // end <class PodPackage>

}

class DoubleType extends FixedSizeType {
  // custom <class DoubleType>
  // end <class DoubleType>

  DoubleType._();
}

class ObjectIdType extends FixedSizeType {
  // custom <class ObjectIdType>
  // end <class ObjectIdType>

  ObjectIdType._();
}

class BooleanType extends FixedSizeType {
  // custom <class BooleanType>
  // end <class BooleanType>

  BooleanType._();
}

class DateType extends FixedSizeType {
  // custom <class DateType>
  // end <class DateType>

  DateType._();
}

class NullType extends FixedSizeType {
  // custom <class NullType>
  // end <class NullType>

  NullType._();
}

class RegexType extends FixedSizeType {
  // custom <class RegexType>
  // end <class RegexType>

  RegexType._();
}

class Int32Type extends FixedSizeType {
  // custom <class Int32Type>
  // end <class Int32Type>

  Int32Type._();
}

class Int64Type extends FixedSizeType {
  // custom <class Int64Type>
  // end <class Int64Type>

  Int64Type._();
}

class TimestampType extends FixedSizeType {
  // custom <class TimestampType>
  // end <class TimestampType>

  TimestampType._();
}

// custom <library ebisu_pod>

final Str = new StrType();
final BinaryData = new BinaryDataType();

final Double = new DoubleType._();
final ObjectId = new ObjectIdType._();
final Boolean = new BooleanType._();
final Date = new DateType._();
final Null = new NullType._();
final Regex = new RegexType._();
final Int32 = new Int32Type._();
final Int64 = new Int64Type._();
final Timestamp = new TimestampType._();

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

PodField field(id, [podType]) =>
    new PodField(makeId(id), podType == null ? Str : podType);

PodObject object(id, [fields]) => new PodObject(makeId(id), fields);

PodArray array(dynamic referredType, {String doc, int maxLength}) =>
    new PodArray(referredType, doc: doc, maxLength: maxLength);

PodField arrayField(id, referredType) => field(id, array(referredType));

StrType fixedStr(int maxLength) => new StrType(maxLength);

// end <library ebisu_pod>
