library ebisu_pod.ebisu_pod;

import 'dart:mirrors';
import 'package:collection/equality.dart';
import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('ebisu_pod');

class PropertyType implements Comparable<PropertyType> {
  static const UDT_PROPERTY = const PropertyType._(0);
  static const FIELD_PROPERTY = const PropertyType._(1);
  static const PACKAGE_PROPERTY = const PropertyType._(2);

  static get values => [UDT_PROPERTY, FIELD_PROPERTY, PACKAGE_PROPERTY];

  final int value;

  int get hashCode => value;

  const PropertyType._(this.value);

  copy() => this;

  int compareTo(PropertyType other) => value.compareTo(other.value);

  String toString() {
    switch (this) {
      case UDT_PROPERTY:
        return "UDT_PROPERTY";
      case FIELD_PROPERTY:
        return "FIELD_PROPERTY";
      case PACKAGE_PROPERTY:
        return "PACKAGE_PROPERTY";
    }
    return null;
  }

  static PropertyType fromString(String s) {
    if (s == null) return null;
    switch (s) {
      case "UDT_PROPERTY":
        return UDT_PROPERTY;
      case "FIELD_PROPERTY":
        return FIELD_PROPERTY;
      case "PACKAGE_PROPERTY":
        return PACKAGE_PROPERTY;
      default:
        return null;
    }
  }
}

/// Convenient access to PropertyType.UDT_PROPERTY with *UDT_PROPERTY* see [PropertyType].
///
/// Property for annotating UDTs ([PodEnum] and [PodObject])
///
const PropertyType UDT_PROPERTY = PropertyType.UDT_PROPERTY;

/// Convenient access to PropertyType.FIELD_PROPERTY with *FIELD_PROPERTY* see [PropertyType].
///
/// Property for annotating [PodField]
///
const PropertyType FIELD_PROPERTY = PropertyType.FIELD_PROPERTY;

/// Convenient access to PropertyType.PACKAGE_PROPERTY with *PACKAGE_PROPERTY* see [PropertyType].
///
/// Property for annotating [PodPackage]
///
const PropertyType PACKAGE_PROPERTY = PropertyType.PACKAGE_PROPERTY;

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

  Iterable get propertyNames => _properties.keys;

  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      String field = MirrorSystem.getName(invocation.memberName);
      final prop = _properties[field];
      if (prop != null) return prop;
    } else if (invocation.isSetter &&
        invocation.positionalArguments.length == 1) {
      String field =
          MirrorSystem.getName(invocation.memberName).replaceAll('=', '');
      _properties[field] = invocation.positionalArguments.first;
      return;
    }

    return super.noSuchMethod(invocation);
  }

  // end <class PropertySet>

  Map<String /* Property Name */, Property> _properties = {};
}

/// A collection of properties that may be associated with elements in a [PodPackage]
class PropertyDefinitionSet {
  /// Indentifier for the set of properties.
  ///
  /// For example, there might be a *capnpPropertyDefinitionSet* designed to
  /// shape the PODS into something that can code generate *capnp* IDL. In
  /// that case the fields might have a *numeric* property to correspond to
  /// the conventinos required by *capnp*.
  Id get id => _id;

  /// Set of [PropertyDefinition]s for fields
  Set<PropertyDefinition> get fieldPropertyDefinitions =>
      _fieldPropertyDefinitions;

  /// Set of [PropertyDefinition]s for udts [objects and enums]
  Set<PropertyDefinition> get udtPropertyDefinitions => _udtPropertyDefinitions;

  /// Set of [PropertyDefinition]s for packages
  Set<PropertyDefinition> get packagePropertyDefinitions =>
      _packagePropertyDefinitions;

  // custom <class PropertyDefinitionSet>
  PropertyDefinitionSet(id) : _id = makeId(id);
  // end <class PropertyDefinitionSet>

  Id _id;
  Set<PropertyDefinition> _fieldPropertyDefinitions = new Set();
  Set<PropertyDefinition> _udtPropertyDefinitions = new Set();
  Set<PropertyDefinition> _packagePropertyDefinitions = new Set();
}

/// Base class for all [PodType]s
abstract class PodType {
  Id get id => _id;

  /// Documentation for fixed size string
  String doc;

  // custom <class PodType>

  PodType(id) : _id = makeId(id);

  bool operator ==(PodType other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType && _id == other._id;

  int get hashCode => _id.hashCode;

  get isArray => this is PodArrayType;
  get isObject => this is PodObject;
  bool get isFixedSize;

  String get typeName => id.snake;

  // end <class PodType>

  Id _id;
}

/// Base class for user defined types
abstract class PodUserDefinedType extends PodType with PropertySet {
  // custom <class PodUserDefinedType>

  PodUserDefinedType(id) : super(id);

  // end <class PodUserDefinedType>

}

/// Represents an enumeration
class PodEnum extends PodUserDefinedType {
  List<String> values = [];

  // custom <class PodEnum>

  bool operator ==(PodEnum other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          _id == other._id &&
          const ListEquality().equals(values, other.values);

  int get hashCode =>
      hash2(super.hashCode, const ListEquality<String>().hash(values).hashCode);

  PodEnum(id, [this.values]) : super(id) {
    if (values == null) {
      values = [];
    }
  }

  bool get isFixedSize => true;

  toString() => chomp(brCompact([
        'PodEnum($id:[${values.join(", ")}])',
        doc == null ? null : blockComment(doc)
      ]));

  // end <class PodEnum>

}

/// Base class for [PodType]s that may have a fixed size specified
abstract class FixedSizeType extends PodType {
  // custom <class FixedSizeType>

  FixedSizeType(id) : super(id);

  // end <class FixedSizeType>

  bool get isFixedSize => true;
}

abstract class VariableSizeType extends PodType {
  /// If non-0 indicates length capped to [max_length]
  int get maxLength => _maxLength;

  // custom <class VariableSizeType>

  VariableSizeType(id, this._maxLength) : super(id);

  bool operator ==(VariableSizeType other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          _id == other._id &&
          _maxLength == other._maxLength;

  int get hashCode => hash2(_maxLength, super.hashCode);

  // end <class VariableSizeType>

  bool get isFixedSize => maxLength != null;

  int _maxLength;
}

/// Used to define string types, which may have a fixed type.
///
/// The primary purpose for modeling data as fixed size strings over the
/// more general string type is so code generators may optimize for speed
/// by allocating space for strings inline.
class StrType extends VariableSizeType {
  // custom <class StrType>

  factory StrType([maxLength, doc]) =>
      _typeCache.putIfAbsent(maxLength, () => new StrType._(maxLength, doc));

  StrType._([maxLength, doc]) : super(_makeTypeId(maxLength), maxLength) {
    this.doc = doc;
  }

  static _makeTypeId(maxLength) =>
      makeId(maxLength == null ? 'str' : 'str_of_${maxLength}');

  toString() => _maxLength == null ? 'Str(VarLen)' : 'StrType($maxLength)';

  get typeName => maxLength == null ? 'str' : 'str($maxLength)';

  // end <class StrType>

  /// Cache of all fixed size strings
  static Map<int, StrType> _typeCache = new Map<int, StrType>();
}

/// Stores binary data as array of bytes
class BinaryDataType extends VariableSizeType {
  // custom <class BinaryDataType>

  factory BinaryDataType([maxLength, doc]) => _typeCache.putIfAbsent(
      maxLength, () => new BinaryDataType._(maxLength, doc));

  BinaryDataType._([maxLength, doc])
      : super(_makeTypeId(maxLength), maxLength) {
    this.doc = doc;
  }

  static _makeTypeId(maxLength) =>
      makeId(maxLength == null ? 'binary_data' : 'binary_data_of_${maxLength}');

  toString() => 'BinaryDataType($maxLength)';
  get typeName => maxLength == null ? 'binary_data' : 'binary_data($maxLength)';

  // end <class BinaryDataType>

  /// Cache of all fixed size BinaryData types
  static Map<int, BinaryDataType> _typeCache = new Map<int, BinaryDataType>();
}

/// A [PodType] that is an array of some [referencedType].
class PodArrayType extends VariableSizeType {
  PodType get referredType => _referredType;

  // custom <class PodArrayType>

  bool operator ==(other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType && _referredType == other._referredType;

  int get hashCode => _referredType.hashCode;

  PodArrayType(referredType, {doc, maxLength})
      : super(_makeTypeId(referredType.id, maxLength), maxLength) {
    this._referredType = referredType;
  }

  static _makeTypeId(Id referredTypeId, maxLength) => makeId(maxLength == null
      ? 'pod_type_array_of_${referredTypeId.snake}'
      : 'pod_type_array_of_${maxLength}_${referredTypeId.snake}');

  toString() => 'PodArrayType($typeName)';

  bool get isFixedSize => maxLength != null;

  // end <class PodArrayType>

  PodType _referredType;
}

/// Combination of owning package name and name of a type within it
class PodTypeRef extends PodType {
  bool operator ==(other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType &&
          _packageName == other._packageName &&
          _resolvedType == other._resolvedType);

  int get hashCode => hash2(_packageName, _resolvedType);

  PackageName get packageName => _packageName;
  PodType get resolvedType => _resolvedType;

  // custom <class PodTypeRef>

  get isFixedSize => _resolvedType.isFixedSize;
  get doc => _resolvedType.doc;
  get isArray => _resolvedType.isArray;
  get isObject => _resolvedType.isObject;
  get podType => _resolvedType == null ? qualifiedTypeName : _resolvedType;

  PodTypeRef.fromQualifiedName(String qualifiedName)
      : super(_makeTypeId(qualifiedName)) {
    final packageNameParts = qualifiedName.split('.');
    _packageName = new PackageName(
        packageNameParts.sublist(0, packageNameParts.length - 1));
  }

  static _makeTypeId(qualifiedName) => qualifiedName.split('.').last;

  get qualifiedTypeName => '$packageName.$typeName';
  toString() => 'PodTypeRef($qualifiedTypeName)';

  // end <class PodTypeRef>

  PackageName _packageName;
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
  List<PodField> fields = [];

  // custom <class PodObject>

  PodObject(id, [this.fields]) : super(id) {
    if (fields == null) {
      fields = [];
    }
  }

  bool operator ==(PodObject other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          _id == other._id &&
          const ListEquality().equals(fields, other.fields);

  int get hashCode => hash2(
      super.hashCode, const ListEquality<PodField>().hash(fields).hashCode);

  bool get isFixedSize => fields.every((f) => f.isFixedSize);

  getField(fieldName) => fields.firstWhere((f) => f.name == fieldName,
      orElse: () =>
          throw new ArgumentError('No field $fieldName in object $typeName'));

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

  /// Any properties associated with this type
  List<PropertyDefinitionSet> get propertyDefinitionSets =>
      _propertyDefinitionSets;

  // custom <class PodPackage>

  PodPackage(name, {Iterable imports, Iterable<PodType> namedTypes}) {
    this.name = name;
    this.imports = (imports != null) ? imports : [];
    this._namedTypes = (namedTypes != null) ? namedTypes : [];
    _allTypes = visitTypes(null);
    _checkNamedTypes();
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

  validateProperties() {
    List errors = [];
    _validatePackageProperties();
    _namedTypes.where((t) => t is PodUserDefinedType).forEach((var udt) {
      udt.propertyNames.forEach((var propName) {
        final def = _propertyDefinitionSets.firstWhere((var pds) {
          final found = pds.udtPropertyDefinitions
              .any((var pd) => pd.id.camel == propName);
          return found;
        }, orElse: () => null);
      });
    });
  }

  _validatePackageProperties() {}

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

  get toLiteral {}

  // end <class PodPackage>

  PackageName _name;
  List<PodPackage> _imports = [];
  List<PodType> _namedTypes = [];

  /// All types within the package including *anonymous* types
  Set _allTypes;
  List<PropertyDefinitionSet> _propertyDefinitionSets = [];
}

class CharType extends FixedSizeType {
  CharType._() : super(new Id('char')) {}
}

class DoubleType extends FixedSizeType {
  DoubleType._() : super(new Id('double')) {}
}

class ObjectIdType extends FixedSizeType {
  ObjectIdType._() : super(new Id('object_id')) {}
}

class BooleanType extends FixedSizeType {
  BooleanType._() : super(new Id('boolean')) {}
}

class DateType extends FixedSizeType {
  DateType._() : super(new Id('date')) {}
}

class NullType extends FixedSizeType {
  NullType._() : super(new Id('null')) {}
}

class RegexType extends FixedSizeType {
  RegexType._() : super(new Id('regex')) {}
}

class Int8Type extends FixedSizeType {
  Int8Type._() : super(new Id('int8')) {}
}

class Int16Type extends FixedSizeType {
  Int16Type._() : super(new Id('int16')) {}
}

class Int32Type extends FixedSizeType {
  Int32Type._() : super(new Id('int32')) {}
}

class Int64Type extends FixedSizeType {
  Int64Type._() : super(new Id('int64')) {}
}

class Uint8Type extends FixedSizeType {
  Uint8Type._() : super(new Id('uint8')) {}
}

class Uint16Type extends FixedSizeType {
  Uint16Type._() : super(new Id('uint16')) {}
}

class Uint32Type extends FixedSizeType {
  Uint32Type._() : super(new Id('uint32')) {}
}

class Uint64Type extends FixedSizeType {
  Uint64Type._() : super(new Id('uint64')) {}
}

class DateTimeType extends FixedSizeType {
  DateTimeType._() : super(new Id('date_time')) {}
}

class TimestampType extends FixedSizeType {
  TimestampType._() : super(new Id('timestamp')) {}
}

// custom <library ebisu_pod>

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

bool allPropertiesValid(Property) => true;

bool propertyValueRequired(PropertyDefinition id, Property property) =>
    property != null &&
    (id.defaultValue == null ||
        (id.defaultValue.runtimeType == property.value.runtimeType));

PropertyDefinition defineUdtProperty(id, String doc,
        {dynamic defaultValue,
        PropertyValueValidPredicate isValueValidPredicate:
            allPropertiesValid}) =>
    new PropertyDefinition(id, UDT_PROPERTY, doc,
        defaultValue: defaultValue,
        isValueValidPredicate: isValueValidPredicate);

PropertyDefinition defineFieldProperty(id, String doc,
        {dynamic defaultValue,
        PropertyValueValidPredicate isValueValidPredicate:
            allPropertiesValid}) =>
    new PropertyDefinition(id, FIELD_PROPERTY, doc,
        defaultValue: defaultValue,
        isValueValidPredicate: isValueValidPredicate);

PropertyDefinition definePackageProperty(id, String doc,
        {dynamic defaultValue,
        PropertyValueValidPredicate isValueValidPredicate:
            allPropertiesValid}) =>
    new PropertyDefinition(id, PACKAGE_PROPERTY, doc,
        defaultValue: defaultValue,
        isValueValidPredicate: isValueValidPredicate);

final Str = new StrType._(null);
final BinaryData = new BinaryDataType._(null);

// end <library ebisu_pod>

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
