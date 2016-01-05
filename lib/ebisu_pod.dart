library ebisu_pod.ebisu_pod;

import 'package:collection/equality.dart';
import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('ebisu_pod');

enum PropertyType {
  /// Property for annotating UDTs ([PodEnum] and [PodObject])
  udtProperty,

  /// Property for annotating [PodField]
  fieldProperty,

  /// Property for annotating [PodPackage]
  packageProperty
}

/// Convenient access to PropertyType.udtProperty with *udtProperty* see [PropertyType].
///
/// Property for annotating UDTs ([PodEnum] and [PodObject])
///
const PropertyType udtProperty = PropertyType.udtProperty;

/// Convenient access to PropertyType.fieldProperty with *fieldProperty* see [PropertyType].
///
/// Property for annotating [PodField]
///
const PropertyType fieldProperty = PropertyType.fieldProperty;

/// Convenient access to PropertyType.packageProperty with *packageProperty* see [PropertyType].
///
/// Property for annotating [PodPackage]
///
const PropertyType packageProperty = PropertyType.packageProperty;

/// Identity of a property that can be associated with a [PodType], [PodField] or [PodPackage]
class PropertyDefinition {
  bool operator ==(PropertyDefinition other) =>
      identical(this, other) ||
      _id == other._id &&
          _propertyType == other._propertyType &&
          _doc == other._doc &&
          _defaultValue == other._defaultValue &&
          _isValueValidPredicate == other._isValueValidPredicate;

  int get hashCode => hashObjects(
      [_id, _propertyType, _doc, _defaultValue, _isValueValidPredicate]);

  /// Id associated with property
  Id get id => _id;

  /// What this [PropertyDefinition] is associated with: [PodType], [PodField] or [PodPackage]
  PropertyType get propertyType => _propertyType;

  /// Documentation for the [PropertyDefinition]/[Property].
  String get doc => _doc;

  /// The default value for a [Property] associated with *this* [PropertyDefinition]
  dynamic get defaultValue => _defaultValue;

  /// Predicate to determine of [Property] identified by [PropertyDefinition] is valid
  PropertyValueValidPredicate get isValueValidPredicate =>
      _isValueValidPredicate;

  // custom <class PropertyDefinition>

  PropertyDefinition(dynamic id, this._propertyType, String thisDoc,
      {dynamic defaultValue,
      PropertyValueValidPredicate isValueValidPredicate: allPropertiesValid})
      : this._id = makeId(id),
        _defaultValue = defaultValue,
        _isValueValidPredicate = isValueValidPredicate;

  bool isValueValid(dynamic value) =>
      _isValueValidPredicate == null ? true : _isValueValidPredicate(value);

  toString() => brCompact([
        'PropertyDefinition(${_id.snake}:$propertyType)',
        indentBlock(brCompact(
            ['----- defaultValue ----', defaultValue, '---- doc ----', doc]))
      ]);

  // end <class PropertyDefinition>

  Id _id;
  PropertyType _propertyType;
  String _doc;
  dynamic _defaultValue;
  PropertyValueValidPredicate _isValueValidPredicate;
}

/// A property associated with a [PodType], [PodField] or [PodPackage]
class Property {
  bool operator ==(Property other) =>
      identical(this, other) ||
      _propertyDefinition == other._propertyDefinition &&
          _value == other._value;

  int get hashCode => hash2(_propertyDefinition, _value);

  /// Reference [PropertyDefinition] for this property
  PropertyDefinition get propertyDefinition => _propertyDefinition;

  /// Value of the property
  dynamic get value => _value;

  // custom <class Property>

  Property(this._propertyDefinition, this._value);

  // end <class Property>

  PropertyDefinition _propertyDefinition;
  dynamic _value;
}

/// A set of properties associated with a [PodTy[e], [PodField] or [PodPackage]
class PropertySet {
  // custom <class PropertySet>

  setProperty(PropertyDefinition propertyDefinition, dynamic value) {
    if (!propertyDefinition.isValueValid(value)) {
      throw new ArgumentError(
          'Failed value: $value is invalid for $propertyDefinition');
    }
    _properties.add(new Property(propertyDefinition, value));
  }

  getPropertyValue(property) {
    final propertyDefinition = makeId(property);
    final prop = _properties.firstWhere(
        (prop) => prop.propertyDefinition.id == propertyDefinition,
        orElse: () => null);
    if (prop != null) {
      return prop.value;
    }
    return null;
  }

  // end <class PropertySet>

  Set<Property> _properties = new Set<Property>();
}

/// A collection of properties that may be associated with elements in a [PodPackage]
class PackagePropertyDefinintionSet {
  /// Set of [PropertyDefinition]s
  Set<PropertyDefinition> get propertyDefinitions => _propertyDefinitions;

  // custom <class PackagePropertyDefinintionSet>
  // end <class PackagePropertyDefinintionSet>

  Set<PropertyDefinition> _propertyDefinitions = new Set();
}

/// Base class for all [PodType]s
class PodType {
  // custom <class PodType>

  PodType();

  get isArray => this is PodArrayType;
  get isObject => this is PodObject;
  bool get isFixedSize;

  Id get id;
  String get doc;
  String get typeName => id.snake;

  // end <class PodType>

}

/// Base class for user defined types
class PodUserDefinedType extends PodType with PropertySet {
  // custom <class PodUserDefinedType>

  setProperty(PropertyDefinition propertyDefinition, dynamic value) {
    if (propertyDefinition.propertyType != udtProperty) {
      throw new ArgumentError('''
Properties assigned to user defined types must be associated with *udtProperty*.
Failed trying to set value ($value) to $propertyDefinition
''');
    }
    super.setProperty(propertyDefinition, value);
  }

  // end <class PodUserDefinedType>

}

/// Represents an enumeration
class PodEnum extends PodUserDefinedType {
  bool operator ==(PodEnum other) =>
      identical(this, other) ||
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

  PodEnum(this._id, [this.values]) {
    if (values == null) {
      values = [];
    }
  }

  toString() => chomp(brCompact([
        'PodEnum($id:[${values.join(", ")}])',
        doc == null ? null : blockComment(doc)
      ]));

  // end <class PodEnum>

  Id _id;
}

/// Base class for [PodType]s that may have a fixed size specified
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

/// A [PodType] that is an array of some [referencedType].
class PodArrayType extends VariableSizeType {
  bool operator ==(PodArrayType other) =>
      identical(this, other) ||
      referredType == other.referredType && doc == other.doc;

  int get hashCode => hash2(referredType, doc);

  PodType referredType;

  /// Documentation for the array
  String doc;

  // custom <class PodArrayType>

  PodArrayType(this.referredType, {this.doc, maxLength}) : super(maxLength) {
    if (this.maxLength == null) this.maxLength = 0;
  }

  toString() => 'PodArrayType(${referredType.typeName})';
  get typeName => referredType.typeName;
  bool get isFixedSize => maxLength > 0;

  // end <class PodArrayType>

}

/// Combination of owning package name and name of a type within it
class PodTypeRef extends PodType {
  bool operator ==(PodTypeRef other) =>
      identical(this, other) ||
      _packageName == other._packageName &&
          _typeName == other._typeName &&
          _resolvedType == other._resolvedType;

  int get hashCode => hash3(_packageName, _typeName, _resolvedType);

  PackageName get packageName => _packageName;
  PodType get resolvedType => _resolvedType;

  // custom <class PodTypeRef>

  get doc => _resolvedType.doc;
  get isArray => _resolvedType.isArray;
  get isObject => _resolvedType.isObject;
  get typeName => _typeName.snake;
  get podType => _resolvedType == null ? qualifiedTypeName : _resolvedType;

  PodTypeRef.fromQualifiedName(String qualifiedName) {
    final packageNameParts = qualifiedName.split('.');
    _packageName = new PackageName(
        packageNameParts.sublist(0, packageNameParts.length - 1));
    _typeName = makeId(packageNameParts.last);
  }

  get qualifiedTypeName => '$packageName.$typeName';
  toString() => 'PodTypeRef($qualifiedTypeName)';

  // end <class PodTypeRef>

  PackageName _packageName;
  Id _typeName;
  PodType _resolvedType;
}

/// A field, which is a named and type entry, in a [PodObject]
class PodField extends Object with PropertySet {
  bool operator ==(PodField other) =>
      identical(this, other) ||
      _id == other._id &&
          doc == other.doc &&
          isIndex == other.isIndex &&
          _podType == other._podType &&
          defaultValue == other.defaultValue &&
          _propertySet == other._propertySet;

  int get hashCode =>
      hashObjects([_id, doc, isIndex, defaultValue, _propertySet]);

  Id get id => _id;

  /// Documentation for the field
  String doc;

  /// If true the field is defined as index
  bool isIndex = false;
  dynamic defaultValue;

  // custom <class PodField>

  dynamic get podType => _podType is PodTypeRef ? _podType.podType : _podType;

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

  /// Returns true if the type is fixed size
  bool get isFixedSize => podType.isFixedSize;

  /// Returns name of [PodField] in *snake_case*
  String get name => _id.snake;

  /// Returns type of [PodField]
  String get typeName => podType.typeName;

  setProperty(PropertyDefinition propertyDefinition, dynamic value) {
    if (propertyDefinition.propertyType != fieldProperty) {
      throw new ArgumentError('''
Properties assigned to a PodField must be associated with *fieldProperty*.
Failed trying to set value ($value) to $propertyDefinition
''');
    }
    super.setProperty(propertyDefinition, value);
  }

  // end <class PodField>

  Id _id;

  /// Type associated with the field.
  ///
  /// May be a PodType, PodTypeRef, or a String.
  /// If it is a String it is converted to a PodTypeRef
  dynamic _podType;

  /// Any properties associated with this type
  String _propertySet = 'new PropertySet()';
}

class PodObject extends PodUserDefinedType {
  bool operator ==(PodObject other) =>
      identical(this, other) ||
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

  bool get isFixedSize => fields.every((f) => f.isFixedSize);

  getField(fieldName) => fields.firstWhere((f) => f.name == fieldName,
      orElse: () =>
          throw new ArgumentError('No field $fieldName in package $name'));

  toString() => brCompact([
        'PodObject($typeName)',
        indentBlock(blockComment(doc)),
        indentBlock(brCompact(fields.map((pf) => [
              '${pf.id}:${pf.podType}',
              pf.doc == null ? null : blockComment(pf.doc)
            ])))
      ]);

  bool get hasArray => fields.any((pf) => pf.podType is PodArrayType);

  bool get hasDefaultedField => fields.any((pf) => pf.defaultValue != null);

  // end <class PodObject>

  Id _id;
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
            : throw new ArgumentError(
                'PackageName must be initialized with List or String'
                ' - not ${path.runtimeType}');
  }

  bool get isQualified => path.isNotEmpty;

  toString() => path.join('.');

  // end <class PackageName>

  List<Id> _path = [];
}

/// Package structure to support organization of pod definitions
class PodPackage extends Entity with PropertySet {
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
    this._namedTypes = (namedTypes != null) ? namedTypes : [];
    _checkNamedTypes();
    _allTypes = visitTypes(null);
  }

  set imports(Iterable imports) {
    this._imports = imports;
  }

  set name(name) {
    this._name = new PackageName(name);
  }

  PodType getType(String typeName) =>
      allTypes.firstWhere((t) => t.typeName == typeName, orElse: () => null);

  PodType getFieldType(String objectName, String fieldName) {
    final podType = getType(objectName);
    assert(podType is PodObject);
    final fieldType = podType.getField(fieldName).podType;
    return fieldType is PodTypeRef ? _resolveType(fieldType) : fieldType;
  }

  /// All types within the package including *anonymous* types
  Set get allTypes {
    if (_allTypes == null) {
      _allTypes = visitTypes(null);
    }

    return _allTypes;
  }

  get podObjects => namedTypes.where((t) => t is PodObject);
  get podEnums => namedTypes.where((t) => t is PodEnum);

  visitTypes(func(PodType)) {
    Set visitedTypes = new Set();

    visitType(podType) {
      assert(podType != null);
      if (podType is PodTypeRef) {
        podType._resolvedType = _resolveType(podType);
        visitType(podType._resolvedType);
      } else {
        if (!visitedTypes.contains(podType)) {
          if (podType is PodObject) {
            for (var field in (podType as PodObject).fields) {
              visitType(field._podType);
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
    var found;
    if (podTypeRef.packageName.isQualified) {
      _logger.info('Look for $podTypeRef in imported packages');
      final package = imports.firstWhere(
          (package) => package.name == podTypeRef.packageName,
          orElse: () => null);
      found = package._findNamedType(podTypeRef.typeName);
    } else {
      _logger.info('Looking for ${podTypeRef.typeName} in *this* package');
      found = _findNamedType(podTypeRef.typeName);
    }

    if (found == null) {
      throw new ArgumentError('Cound not find type for $podTypeRef');
    }
    _logger.info('Search result $podTypeRef -> ${found.typeName}');
    return found;
  }

  _findNamedType(typeName) =>
      namedTypes.singleWhere((t) => t.typeName == typeName);

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

  /// Any properties associated with this type
  PropertySet _propertySet = new PropertySet();
}

class CharType extends FixedSizeType {
  final Id id = makeId("char");

  // custom <class CharType>
  // end <class CharType>

  CharType._();
  toString() => typeName;
}

class DoubleType extends FixedSizeType {
  final Id id = makeId("double");

  // custom <class DoubleType>
  // end <class DoubleType>

  DoubleType._();
  toString() => typeName;
}

class ObjectIdType extends FixedSizeType {
  final Id id = makeId("object_id");

  // custom <class ObjectIdType>
  // end <class ObjectIdType>

  ObjectIdType._();
  toString() => typeName;
}

class BooleanType extends FixedSizeType {
  final Id id = makeId("boolean");

  // custom <class BooleanType>
  // end <class BooleanType>

  BooleanType._();
  toString() => typeName;
}

class DateType extends FixedSizeType {
  final Id id = makeId("date");

  // custom <class DateType>
  // end <class DateType>

  DateType._();
  toString() => typeName;
}

class NullType extends FixedSizeType {
  final Id id = makeId("null");

  // custom <class NullType>
  // end <class NullType>

  NullType._();
  toString() => typeName;
}

class RegexType extends FixedSizeType {
  final Id id = makeId("regex");

  // custom <class RegexType>
  // end <class RegexType>

  RegexType._();
  toString() => typeName;
}

class Int8Type extends FixedSizeType {
  final Id id = makeId("int8");

  // custom <class Int8Type>
  // end <class Int8Type>

  Int8Type._();
  toString() => typeName;
}

class Int16Type extends FixedSizeType {
  final Id id = makeId("int16");

  // custom <class Int16Type>
  // end <class Int16Type>

  Int16Type._();
  toString() => typeName;
}

class Int32Type extends FixedSizeType {
  final Id id = makeId("int32");

  // custom <class Int32Type>
  // end <class Int32Type>

  Int32Type._();
  toString() => typeName;
}

class Int64Type extends FixedSizeType {
  final Id id = makeId("int64");

  // custom <class Int64Type>
  // end <class Int64Type>

  Int64Type._();
  toString() => typeName;
}

class Uint8Type extends FixedSizeType {
  final Id id = makeId("uint8");

  // custom <class Uint8Type>
  // end <class Uint8Type>

  Uint8Type._();
  toString() => typeName;
}

class Uint16Type extends FixedSizeType {
  final Id id = makeId("uint16");

  // custom <class Uint16Type>
  // end <class Uint16Type>

  Uint16Type._();
  toString() => typeName;
}

class Uint32Type extends FixedSizeType {
  final Id id = makeId("uint32");

  // custom <class Uint32Type>
  // end <class Uint32Type>

  Uint32Type._();
  toString() => typeName;
}

class Uint64Type extends FixedSizeType {
  final Id id = makeId("uint64");

  // custom <class Uint64Type>
  // end <class Uint64Type>

  Uint64Type._();
  toString() => typeName;
}

class DateTimeType extends FixedSizeType {
  final Id id = makeId("date_time");

  // custom <class DateTimeType>
  // end <class DateTimeType>

  DateTimeType._();
  toString() => typeName;
}

class TimestampType extends FixedSizeType {
  final Id id = makeId("timestamp");

  // custom <class TimestampType>
  // end <class TimestampType>

  TimestampType._();
  toString() => typeName;
}

// custom <library ebisu_pod>

final Str = new StrType();
final BinaryData = new BinaryDataType();

final Char = new CharType._();
final Double = new DoubleType._();
final ObjectId = new ObjectIdType._();
final Boolean = new BooleanType._();
final Date = new DateType._();
final Null = new NullType._();
final Regex = new RegexType._();
final Int8 = new Int8Type._();
final Int16 = new Int16Type._();
final Int32 = new Int32Type._();
final Int64 = new Int64Type._();

final Uint8 = new Uint8Type._();
final Uint16 = new Uint16Type._();
final Uint32 = new Uint32Type._();
final Uint64 = new Uint64Type._();
final DateTime = new DateTimeType._();
final Timestamp = new TimestampType._();

final DoubleArray = array(Double, doc: 'Array<double>');
final StringArray = array(Str, doc: 'Array<Str>');
final BinaryDataArray = array(BinaryData, doc: 'Array<BinaryData>');
final ObjectIdArray = array(ObjectId, doc: 'Array<ObjectId>');
final BooleanArray = array(Boolean, doc: 'Array<Boolean>');
final DateArray = array(Date, doc: 'Array<Date>');
final RegexArray = array(Regex, doc: 'Array<Regex>');

final Int8Array = array(Int8, doc: 'Array<Int8>');
final Int16Array = array(Int16, doc: 'Array<Int16>');
final Int32Array = array(Int32, doc: 'Array<Int32>');
final Int64Array = array(Int64, doc: 'Array<Int64>');

final Uint8Array = array(Uint8, doc: 'Array<Uint8>');
final Uint16Array = array(Uint16, doc: 'Array<Uint16>');
final Uint32Array = array(Uint32, doc: 'Array<Uint32>');
final Uint64Array = array(Uint64, doc: 'Array<Uint64>');
final DateTimeArray = array(DateTime, doc: 'Array<DateTime>');
final TimestampArray = array(Timestamp, doc: 'Array<Timestamp>');

PodEnum enum_(id, [values]) => new PodEnum(makeId(id), values);

PodField field(id, [podType]) =>
    new PodField(makeId(id), podType == null ? Str : podType);

PodObject object(id, [fields]) => new PodObject(makeId(id), fields);

PodArrayType array(dynamic referredType, {String doc, int maxLength}) =>
    new PodArrayType(referredType, doc: doc, maxLength: maxLength);

StrType fixedStr(int maxLength) => new StrType(maxLength);

PodPackage package(packageName, {imports, namedTypes}) =>
    new PodPackage(packageName, imports: imports, namedTypes: namedTypes);

_makeValidIdPart(part) => makeId(part);
_makeValidPath(path) => path.map(_makeValidIdPart).toList();

typedef bool PropertyRequiredPredicate(Property);
typedef bool PropertyValueValidPredicate(dynamic value);

bool allPropertiesValid(PropertyDefinition id, Property) => true;

bool propertyValueRequired(PropertyDefinition id, Property property) =>
    property != null &&
    (id.defaultValue == null ||
        (id.defaultValue.runtimeType == property.value.runtimeType));

PropertyDefinition defineUdtProperty(id, String doc,
        {dynamic defaultValue,
        PropertyValueValidPredicate isValueValidPredicate:
            allPropertiesValid}) =>
    new PropertyDefinition(id, udtProperty, doc,
        defaultValue: defaultValue,
        isValueValidPredicate: isValueValidPredicate);

PropertyDefinition defineFieldProperty(id, String doc,
        {dynamic defaultValue,
        PropertyValueValidPredicate isValueValidPredicate:
            allPropertiesValid}) =>
    new PropertyDefinition(id, fieldProperty, doc,
        defaultValue: defaultValue,
        isValueValidPredicate: isValueValidPredicate);

PropertyDefinition definePackageProperty(id, String doc,
        {dynamic defaultValue,
        PropertyValueValidPredicate isValueValidPredicate:
            allPropertiesValid}) =>
    new PropertyDefinition(id, packageProperty, doc,
        defaultValue: defaultValue,
        isValueValidPredicate: isValueValidPredicate);

// end <library ebisu_pod>
