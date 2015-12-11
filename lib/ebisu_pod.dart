library ebisu_pod.ebisu_pod;

import 'package:collection/equality.dart';
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
  bool operator ==(PodEnum other) => identical(this, other) ||
      _id == other._id &&
          const ListEquality().equals(values, other.values) &&
          doc == other.doc;

  int get hashCode =>
      hash3(_id, const ListEquality<String>().hash(values), doc);

  Id get id => _id;
  List<String> values = [];

  /// Documentation for the enum
  String doc;

  // custom <class PodEnum>

  get name => id.snake;

  PodEnum(this._id, [this.values]) {
    if (values == null) {
      values = [];
    }
  }

  String get typeName => name;
  toString() => chomp(brCompact([
        'PodEnum($id:[${values.join(", ")}])',
        doc == null ? null : blockComment(doc)
      ]));

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
  get typeName => maxLength == null ? 'str' : 'str($maxLength)';

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
  get typeName => maxLength == null ? 'binary_data' : 'binary_data($maxLength)';

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
  get typeName => referredType.typeName;
  bool get isFixedSize => maxLength > 0;

  // end <class PodArray>

}

/// Combination of owning package name and name of a type within it
class PodTypeRef {
  bool operator ==(PodTypeRef other) => identical(this, other) ||
      _packageName == other._packageName && _typeName == other._typeName;

  int get hashCode => hash2(_packageName, _typeName);

  PackageName get packageName => _packageName;

  // custom <class PodTypeRef>

  PodTypeRef.fromQualifiedName(String qualifiedName) {
    final packageNameParts = qualifiedName.split('.');
    _packageName = new PackageName(
        packageNameParts.sublist(0, packageNameParts.length - 1));
    _typeName = makeId(packageNameParts.last);
  }

  get typeName => _typeName.snake;
  get qualifiedTypeName => '$packageName.$typeName';
  toString() => 'PodTypeRef($qualifiedTypeName)';

  // end <class PodTypeRef>

  PackageName _packageName;
  Id _typeName;
}

class PodField {
  bool operator ==(PodField other) => identical(this, other) ||
      _id == other._id &&
          isIndex == other.isIndex &&
          _podType == other._podType &&
          defaultValue == other.defaultValue &&
          doc == other.doc;

  int get hashCode => hash4(_id, isIndex, defaultValue, doc);

  Id get id => _id;

  /// If true the field is defined as index
  bool isIndex = false;

  /// Type associated with the field.
  ///
  /// May be a PodType, PodTypeRef, or a String.
  /// If it is a String it is converted to a PodTypeRef
  dynamic get podType => _podType;
  dynamic defaultValue;

  /// Documentation for the field
  String doc;

  // custom <class PodField>

  PodField(this._id, [podType]) {
    this.podType = podType;
  }

  set podType(dynamic podType) =>
      _podType = (podType is PodType || PodType is PodTypeRef)
          ? podType
          : podType is String
              ? new PodTypeRef.fromQualifiedName(podType)
              : throw new ArgumentError(
                  'PodField.podType can only be assigned PodType or PodTypeRef '
                  '- not ${podType.runtimeType}');

  toString() => brCompact([
        'PodField($id:$podType:default=$defaultValue)',
        indentBlock(blockComment(doc))
      ]);

  bool get isFixedSize => podType.isFixedSize;
  String get name => _id.snake;
  String get typeName => podType.typeName;

  // end <class PodField>

  Id _id;
  dynamic _podType;
}

class PodObject extends PodType {
  bool operator ==(PodObject other) => identical(this, other) ||
      _id == other._id &&
          const ListEquality().equals(fields, other.fields) &&
          doc == other.doc;

  int get hashCode =>
      hash3(_id, const ListEquality<PodField>().hash(fields), doc);

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

  get name => id.snake;
  get typeName => name;

  bool get isFixedSize => fields.every((f) => f.isFixedSize);

  getField(fieldName) =>
      fields.firstWhere((f) => f.name == fieldName, orElse: () => null);

  toString() => brCompact([
        'PodObject($typeName)',
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
  bool operator ==(PackageName other) =>
      identical(this, other) || const ListEquality().equals(_path, other._path);

  int get hashCode => const ListEquality<Id>().hash(_path).hashCode;

  List<Id> get path => _path;

  // custom <class PackageName>

  PackageName(dynamic path) {
    this._path = path is List
        ? _makeValidPath(path)
        : path is String
            ? path.split('.').map(_makeValidIdPart).toList()
            : throw ArgumentError(
                'PackageName must be initialized with List or String'
                ' - not ${path.runtimeType}');
  }

  bool get isQualified => path.isEmpty;

  toString() => path.join('.');

  // end <class PackageName>

  List<Id> _path = [];
}

/// Package structure to support organization of pod definitions
class PodPackage extends Entity {
  /// Name of package
  PackageName get name => _name;

  /// Packages required by (ie containing referenced types) this package
  List<PodPackage> get imports => _imports;

  /// The named and therefore referencable types within the package
  List<PodType> get namedTypes => _namedTypes;

  // custom <class PodPackage>

  PodPackage(name, {Iterable imports, Iterable<PodType> namedTypes}) {
    this.name = name;
    this.imports = (imports != null) ? imports : [];
    this.namedTypes = (namedTypes != null) ? namedTypes : [];
  }

  set imports(Iterable imports) {
    this._imports =
        imports.map((i) => i is PackageName ? i : new PackageName(i)).toList();
  }

  set name(name) {
    this._name = new PackageName(name);
  }

  PodType getType(typeName) =>
      allTypes.firstWhere((t) => t.typeName == typeName, orElse: () => null);

  set namedTypes(Iterable<PodType> namedTypes) {
    _namedTypes = namedTypes.toList();
    _checkNamedTypes();
    _allTypes = null;
  }

  /// All types within the package including *anonymous* types
  Set get allTypes {
    if (_allTypes == null) {
      _allTypes = visitTypes(null);
    }

    return _allTypes;
  }

  visitTypes(func(PodType)) {
    Set visitedTypes = new Set();

    visitType(podType) {
      if (podType is PodTypeRef) {
        visitType(_resolveType(podType));
      } else {
        if (!visitedTypes.contains(podType)) {
          if (podType is PodObject) {
            for (var field in (podType as PodObject).fields) {
              visitType(field.podType);
            }
          }

          _logger.info('Visiting ${podType.typeName}');
          if (func != null) func(podType);
          visitedTypes.add(podType);
        }
      }
    }

    for (var podType in _namedTypes) {
      visitType(podType);
    }
    return visitedTypes;
  }

  _resolveType(PodTypeRef podTypeRef) {
    if (podTypeRef.packageName.isQualified) {
      _logger.info('Looking for ${podTypeRef.typeName} in *this* package');
      final found =
          namedTypes.singleWhere((t) => t.typeName == podTypeRef.typeName);
      _logger.info('Search result $podTypeRef -> ${found.typeName}');
      return found;
    } else {
      _logger.info('Look for $podTypeRef in imported packages');
    }
  }

  toString() => brCompact([
        'PodPackage($name)',
        indentBlock(
            brCompact(allTypes.map((t) => '${t.runtimeType}(${t.typeName})')))
      ]);

  get details => brCompact([
        'PodPackage($name)',
        indentBlock(br(allTypes.map((t) => t.toString()),
            '\n----------------------------------\n'))
      ]);

  _checkNamedTypes() {
    if (!namedTypes
        .every((namedType) => namedType is PodObject || namedType is PodEnum)) {
      throw new ArgumentError(
          'PodPackage named types must be PodObjects or named PodEnums');
    }
    final unique = new Set();
    final duplicate =
        allTypes.firstWhere((t) => !unique.add(t.typeName), orElse: () => null);
    if (duplicate != null) {
      throw new ArgumentError(
          'PodPackage named types must unique - duplicate: $duplicate');
    }
  }

  // end <class PodPackage>

  PackageName _name;
  List<PodPackage> _imports = [];
  List<PodType> _namedTypes = [];

  /// All types within the package including *anonymous* types
  Set _allTypes;
}

class DoubleType extends FixedSizeType {
  // custom <class DoubleType>
  // end <class DoubleType>

  DoubleType._();
  get typeName => 'double';
  toString() => typeName;
}

class ObjectIdType extends FixedSizeType {
  // custom <class ObjectIdType>
  // end <class ObjectIdType>

  ObjectIdType._();
  get typeName => 'object_id';
  toString() => typeName;
}

class BooleanType extends FixedSizeType {
  // custom <class BooleanType>
  // end <class BooleanType>

  BooleanType._();
  get typeName => 'boolean';
  toString() => typeName;
}

class DateType extends FixedSizeType {
  // custom <class DateType>
  // end <class DateType>

  DateType._();
  get typeName => 'date';
  toString() => typeName;
}

class NullType extends FixedSizeType {
  // custom <class NullType>
  // end <class NullType>

  NullType._();
  get typeName => 'null';
  toString() => typeName;
}

class RegexType extends FixedSizeType {
  // custom <class RegexType>
  // end <class RegexType>

  RegexType._();
  get typeName => 'regex';
  toString() => typeName;
}

class Int32Type extends FixedSizeType {
  // custom <class Int32Type>
  // end <class Int32Type>

  Int32Type._();
  get typeName => 'int32';
  toString() => typeName;
}

class Int64Type extends FixedSizeType {
  // custom <class Int64Type>
  // end <class Int64Type>

  Int64Type._();
  get typeName => 'int64';
  toString() => typeName;
}

class TimestampType extends FixedSizeType {
  // custom <class TimestampType>
  // end <class TimestampType>

  TimestampType._();
  get typeName => 'timestamp';
  toString() => typeName;
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

PodPackage package(packageName, {imports, namedTypes}) =>
    new PodPackage(packageName, imports: imports, namedTypes: namedTypes);

_makeValidIdPart(part) => makeId(part);
_makeValidPath(path) => path.map(_makeValidIdPart).toList();

// end <library ebisu_pod>
