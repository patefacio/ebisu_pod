library ebisu_pod.ebisu_pod;

import 'dart:mirrors';
import 'package:collection/collection.dart';
import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';
import 'package:quiver/iterables.dart';

// custom <additional imports>
// end <additional imports>

final Logger _logger = new Logger('ebisu_pod');

class PropertyType implements Comparable<PropertyType> {
  /// Property for annotating UDTs ([PodEnum] and [PodObject])
  static const PropertyType UDT_PROPERTY = const PropertyType._(0);

  /// Property for annotating [PodField]
  static const PropertyType FIELD_PROPERTY = const PropertyType._(1);

  /// Property for annotating [PodPackage]
  static const PropertyType PACKAGE_PROPERTY = const PropertyType._(2);

  static List<PropertyType> get values =>
      const <PropertyType>[UDT_PROPERTY, FIELD_PROPERTY, PACKAGE_PROPERTY];

  final int value;

  int get hashCode => value;

  const PropertyType._(this.value);

  PropertyType copy() => this;

  int compareTo(PropertyType other) => value.compareTo(other.value);

  String toString() {
    switch (this) {
      case UDT_PROPERTY:
        return "udt_property";
      case FIELD_PROPERTY:
        return "field_property";
      case PACKAGE_PROPERTY:
        return "package_property";
    }
    return null;
  }

  static PropertyType fromString(String s) {
    if (s == null) return null;
    switch (s) {
      case "udt_property":
        return UDT_PROPERTY;
      case "field_property":
        return FIELD_PROPERTY;
      case "package_property":
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

/// Indicates an attempt to access an invalid property
class PropertyError {
  const PropertyError(this.propertyType, this.itemAccessed, this.property);

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is PropertyError &&
          propertyType == other.propertyType &&
          itemAccessed == other.itemAccessed &&
          property == other.property);

  @override
  int get hashCode => hash3(propertyType, itemAccessed, property);

  final PropertyType propertyType;
  final String itemAccessed;
  final String property;

  // custom <class PropertyError>

  toString() => 'PropertyError($propertyType, $itemAccessed, $property)';

  // end <class PropertyError>

}

/// Identity of a property that can be associated with a [PodType], [PodField] or [PodPackage]
class PropertyDefinition {
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is PropertyDefinition &&
          _id == other._id &&
          _propertyType == other._propertyType &&
          _doc == other._doc &&
          _defaultValue == other._defaultValue &&
          _isValueValidPredicate == other._isValueValidPredicate);

  @override
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
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Property &&
          _propertyDefinition == other._propertyDefinition &&
          _value == other._value);

  @override
  int get hashCode => hash2(_propertyDefinition, _value);

  /// Reference [PropertyDefinition] for this property
  PropertyDefinition get propertyDefinition => _propertyDefinition;

  /// Value of the property
  dynamic get value => _value;

  // custom <class Property>

  Property(this._propertyDefinition, this._value);

  get valueString => _value.toString();

  // end <class Property>

  PropertyDefinition _propertyDefinition;
  dynamic _value;
}

/// A set of properties associated with a [PodTy[e], [PodField] or [PodPackage]
abstract class PropertySet {
  // custom <class PropertySet>

  Iterable get propertyNames => _properties.keys;

  String get name;

  mapProperties(f(propName, property)) =>
      propertyNames.map((pn) => f(pn, _properties[pn]));

  setProperty(String propName, propValue) {
    if (propValue is Property) {
      _properties[propName] = propValue;
    } else {
      final id = makeId(propName);
      final propertyType = (this is PodEnum || this is PodObject)
          ? PropertyType.UDT_PROPERTY
          : this is PodPackage
              ? PropertyType.PACKAGE_PROPERTY
              : PropertyType.FIELD_PROPERTY;

      _properties[propName] =
          Property(PropertyDefinition(id, propertyType, null), propValue);
    }
  }

  Property getProperty(String propName) => _properties[propName];

  Iterable<PropertyError> getPropertyErrors(
      List<PropertyDefinitionSet> propertyDefinitionSets);

  Iterable<PropertyError> _getPropertyErrors(PropertyType propertyType,
      List<PropertyDefinitionSet> propertyDefinitionSets) {
    List<PropertyError> errors = [];
    propertyNames.forEach((var propName) {
      final matching = propertyDefinitionSets.firstWhere((var pds) {
        final found = pds
            .getPropertyDefinitions(propertyType)
            .any((var pd) => pd.id.camel == propName);
        return found;
      }, orElse: () => null);

      if (matching == null) {
        errors.add(new PropertyError(propertyType, this.name, propName));
      }
    });
    return errors;
  }

  get propertyDetails => brCompact([
        name,
        '--- properties ---',
        indentBlock(
            brCompact(_properties.keys.map((p) => '$p -> ${_properties[p]}'))),
      ]);

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

  Set<PropertyDefinition> getPropertyDefinitions(propertyType) =>
      propertyType == FIELD_PROPERTY
          ? _fieldPropertyDefinitions
          : propertyType == UDT_PROPERTY
              ? _udtPropertyDefinitions
              : _packagePropertyDefinitions;

  toString() => brCompact([
        '---------- udt property definitions ----------',
        indentBlock(brCompact(udtPropertyDefinitions)),
        '---------- field property definitions ----------',
        indentBlock(brCompact(fieldPropertyDefinitions)),
        '---------- package property definitions ----------',
        indentBlock(brCompact(packagePropertyDefinitions)),
      ]);

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

  bool operator ==(other) =>
      identical(this, other) || other is PodType && _id == other._id;

  int get hashCode => _id.hashCode;

  get isArray => this is PodArrayType;
  get isFixedSizeArray => isArray && isFixedSize;
  get isVariableArray => isArray && !isFixedSize;
  get isObject => this is PodObject;
  bool get isFixedSize;

  String get typeName => id.snake;

  // end <class PodType>

  Id _id;
}

/// Represents types that exist in target language
class PodPredefinedType extends PodType with PropertySet {
  // custom <class PodPredefinedType>

  PodPredefinedType(id) : super(id);

  Iterable<PropertyError> getPropertyErrors(
          List<PropertyDefinitionSet> propertyDefinitionSets) =>
      _getPropertyErrors(UDT_PROPERTY, propertyDefinitionSets);

  get name => _id.snake;

  get isFixedSize => true;

  // end <class PodPredefinedType>

}

/// Base class for user defined types
abstract class PodUserDefinedType extends PodType with PropertySet {
  // custom <class PodUserDefinedType>

  PodUserDefinedType(id) : super(id);

  Iterable<PropertyError> getPropertyErrors(
          List<PropertyDefinitionSet> propertyDefinitionSets) =>
      _getPropertyErrors(UDT_PROPERTY, propertyDefinitionSets);

  get name => _id.snake;

  // end <class PodUserDefinedType>

}

/// Combines the enumerant id and optionally a doc string
class EnumValue {
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is EnumValue && id == other.id && doc == other.doc);

  @override
  int get hashCode => hash2(id, doc);

  Id id;

  /// Description of enumerant
  String doc;

  // custom <class EnumValue>

  EnumValue(id, [this.doc]) : id = makeId(id);

  toString() => id.snake;

  // end <class EnumValue>

}

/// Represents an enumeration
class PodEnum extends PodUserDefinedType {
  List<EnumValue> get values => _values;

  // custom <class PodEnum>

  bool operator ==(other) =>
      identical(this, other) ||
      (other is PodEnum &&
          runtimeType == other.runtimeType &&
          _id == other._id &&
          const ListEquality().equals(values, other.values));

  int get hashCode => hash2(
      super.hashCode, const ListEquality<EnumValue>().hash(values).hashCode);

  PodEnum(id, [Iterable values]) : super(id) {
    this.values = values;
  }

  set values(Iterable values) {
    this._values = values?.map(_makeEv)?.toList() ?? [];
  }

  static EnumValue _makeEv(dynamic v) => v is EnumValue
      ? v
      : v is String || v is Id
          ? new EnumValue(v)
          : throw 'EnumValue must be String, Id or EnumValue: $v';

  bool get isFixedSize => true;

  toString() => chomp(brCompact([
        'PodEnum($id)',
        indentBlock(
            brCompact(['----- doc -----', (doc ?? ''), '----- values -----'])),
        indentBlock(brCompact(values))
      ]));

  // end <class PodEnum>

  List<EnumValue> _values = [];
}

/// Base class for [PodType]s that may have a fixed size specified
abstract class FixedSizeType extends PodType {
  // custom <class FixedSizeType>

  FixedSizeType(id) : super(id);

  // end <class FixedSizeType>

  bool get isFixedSize => true;
}

/// Provides support for variable sized type like strings and arrays.
///
/// A [maxLength] may be associated with the type to indicate it is fixed
/// length. Assignment to [maxLength] must be of type _int_ or [PodConstant].
abstract class VariableSizeType extends PodType {
  /// If non-0 indicates length capped to [max_length]
  dynamic get maxLength => _maxLength;

  // custom <class VariableSizeType>

  VariableSizeType(id, maxLength) : super(id) {
    this.maxLength = maxLength;
  }

  bool operator ==(other) =>
      identical(this, other) ||
      (other is VariableSizeType &&
          runtimeType == other.runtimeType &&
          _id == other._id &&
          _maxLength == other._maxLength);

  int get hashCode => hash2(_maxLength, super.hashCode);

  set maxLength(maxLength) => _maxLength = (maxLength == null ||
          maxLength is int ||
          maxLength is PodConstant)
      ? maxLength
      : throw 'maxLength for VariableSizeTypes must be int or PodConstant - not $maxLength';

  // end <class VariableSizeType>

  bool get isFixedSize => maxLength != null;

  dynamic _maxLength;
}

/// Represents a constant
class PodConstant {
  PodConstant(this._id, this.podType, this.value);

  Id get id => _id;

  /// Type of the constant
  PodType podType;

  /// Value for the constant
  dynamic value;

  // custom <class PodConstant>

  toString() => 'PodConstant(${id.snake}, $podType, $value)';

  get encodedId => makeId('${id.snake}_${podType.id.snake}_$value');

  // end <class PodConstant>

  Id _id;
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

  static _makeTypeId(maxLength) => _makePrefixedTypeId('str', maxLength);

  toString() => _maxLength == null ? 'Str(VarLen)' : 'StrType($maxLength)';

  get typeName => maxLength == null ? 'str' : 'str_$maxLength';

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
      _makePrefixedTypeId('binary_data', maxLength);

  toString() => 'BinaryDataType($maxLength)';
  get typeName => maxLength == null ? 'binary_data' : 'binary_data($maxLength)';

  // end <class BinaryDataType>

  /// Cache of all fixed size BinaryData types
  static Map<int, BinaryDataType> _typeCache = new Map<int, BinaryDataType>();
}

/// Model related bits
class BitSetType extends PodType {
  /// Number of bits in the set
  int numBits;

  /// Any bit padding after identified [num_bits] bits
  int rhsPadBits = 0;

  /// Any bit padding in front of identified [num_bits] bits
  int lhsPadBits = 0;

  // custom <class BitSetType>

  BitSetType(id, this.numBits, {rhsPadBits, lhsPadBits})
      : this.rhsPadBits = rhsPadBits ?? 0,
        this.lhsPadBits = lhsPadBits ?? 0,
        super(id) {}

  bool get isFixedSize => true;

  toString() => brCompact([
        'BitSet($id:$rhsPadBits:$numBits:$lhsPadBits)',
        doc == null ? null : indentBlock(blockComment(doc))
      ]);

  // end <class BitSetType>

}

/// A [PodType] that is an array of some [referencedType].
///
/// A [maxLength] may be associated with the type to indicate it is fixed
/// length. Assignment to [maxLength] must be of type _int_ or [PodConstant].
class PodArrayType extends VariableSizeType {
  // custom <class PodArrayType>

  bool operator ==(other) =>
      identical(this, other) ||
      other is PodArrayType && referredType == other.referredType;

  int get hashCode => _referredType.hashCode;

  PodArrayType(referredType, {doc, maxLength})
      : super(
            _makeTypeId(_referredTypeId(referredType), maxLength), maxLength) {
    this.referredType = referredType;
  }

  PodType get referredType =>
      _referredType is PodTypeRef ? _referredType.podType : _referredType;

  set referredType(dynamic referredType) =>
      _referredType = _normalizeReferredType(referredType);

  toString() => 'PodArrayType($typeName:$maxLength)';

  bool get isFixedSize => maxLength != null;

  static _makeTypeId(Id referredTypeId, maxLength) =>
      _makePrefixedTypeId('array_of_${referredTypeId.snake}', maxLength);

  // end <class PodArrayType>

  /// Type associated with the field.
  ///
  /// May be a PodType, PodTypeRef, or a String.
  /// If it is a String it is converted to a PodTypeRef
  dynamic _referredType;
}

/// A [PodType] that is a map of some [keyReferencedType] to some [valueReferenceType].
class PodMapType extends PodType {
  // custom <class PodMapType>

  PodMapType(keyReferredType, valueReferredType, {doc})
      : super(
            'map_of_${_referredTypeId(keyReferredType).snake}_to_${_referredTypeId(valueReferredType).snake}') {
    this.keyReferredType = _normalizeReferredType(keyReferredType);
    this.valueReferredType = _normalizeReferredType(valueReferredType);
    this.doc = doc;
  }

  set keyReferredType(dynamic referredType) =>
      _keyReferredType = _normalizeReferredType(referredType);

  get keyReferredType => _keyReferredType is PodTypeRef
      ? _keyReferredType.podType
      : _keyReferredType;

  get valueReferredType => _valueReferredType is PodTypeRef
      ? _valueReferredType.podType
      : _valueReferredType;

  set valueReferredType(dynamic referredType) =>
      _valueReferredType = _normalizeReferredType(referredType);

  bool get isFixedSize => false;

  toString() => 'PodMapType($keyReferredType:$valueReferredType)';

  // end <class PodMapType>

  /// Type associated with the key field.
  ///
  /// May be a PodType, PodTypeRef, or a String.
  /// If it is a String it is converted to a PodTypeRef
  dynamic _keyReferredType;

  /// Type associated with the value field.
  ///
  /// May be a PodType, PodTypeRef, or a String.
  /// If it is a String it is converted to a PodTypeRef
  dynamic _valueReferredType;
}

/// Combination of owning package name and name of a type within it
class PodTypeRef extends PodType {
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType &&
          _packageName == other._packageName &&
          _resolvedType == other._resolvedType);

  @override
  int get hashCode => hash2(_packageName, _resolvedType);

  PackageName get packageName => _packageName;
  PodType get resolvedType => _resolvedType;

  // custom <class PodTypeRef>

  get isFixedSize => _resolvedType.isFixedSize;
  get doc => _resolvedType.doc;
  get isArray => _resolvedType.isArray;
  get isFixedSizeArray => _resolvedType.isFixedSizeArray;
  get isVariableArray => _resolvedType.isVariableArray;
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
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is PodField &&
          _id == other._id &&
          doc == other.doc &&
          isIndex == other.isIndex &&
          _podType == other._podType &&
          defaultValue == other.defaultValue &&
          isOptional == other.isOptional);

  @override
  int get hashCode =>
      hashObjects([_id, doc, isIndex, defaultValue, isOptional]);

  Id get id => _id;

  /// Documentation for the field
  String doc;

  /// If true the field is defined as index
  bool isIndex = false;

  /// A default value for the field
  dynamic defaultValue;

  /// If set this field is optional - indicating [null] or `None` is acceptable
  bool isOptional = false;
  PodObject get owner => _owner;

  // custom <class PodField>

  dynamic get podType => _podType is PodTypeRef ? _podType.podType : _podType;

  PodField(this._id, [podType]) {
    this.podType = podType;
  }

  Iterable<PropertyError> getPropertyErrors(
          List<PropertyDefinitionSet> propertyDefinitionSets) =>
      _getPropertyErrors(FIELD_PROPERTY, propertyDefinitionSets);

  set podType(dynamic podType) =>
      _podType = (podType is PodType || podType is PodTypeRef)
          ? podType
          : podType is String
              ? new PodTypeRef.fromQualifiedName(podType)
              : throw new ArgumentError(
                  'PodField.podType can only be assigned PodType or PodTypeRef '
                  '- not ${podType.runtimeType}');

  toString() => brCompact([
        'PodField($id:$podType)',
        indentBlock('default=$defaultValue'),
        indentBlock(blockComment(doc)),
        indentBlock(propertyDetails),
      ]);

  /// Returns true if the type is fixed size
  bool get isFixedSize => podType.isFixedSize;

  /// Returns name of [PodField] in *snake_case*
  get name => _id.snake;

  /// Returns type of [PodField]
  String get typeName => podType.typeName;

  // end <class PodField>

  Id _id;

  /// Type associated with the field.
  ///
  /// May be a PodType, PodTypeRef, or a String.
  /// If it is a String it is converted to a PodTypeRef
  dynamic _podType;
  PodObject _owner;
}

/// Represents the list of fields from some top level [PodObject] to a given field.
class FieldPath {
  FieldPath(this.path);

  /// Fields from top level [PodObject] to a leaf field
  List<PodField> path = [];

  // custom <class FieldPath>

  /// Returns the number of placeholders (strings representing keys in maps) to
  /// fully qualify the path to field
  int get numPlaceHolders => path.where((f) => f == null).length;

  /// Returns the [PodType] of the field the path points to
  PodType get fieldPodType => path.last.podType;

  /// The dot-qualified string of field names to the leaf field
  String get pathKey => path.map((f) => f?.id?.camel ?? '').join('.');

  // end <class FieldPath>

}

class PodObject extends PodUserDefinedType {
  List<PodField> get fields => _fields;

  /// Indicates [PodObject] should have one and only one of the fields present
  bool isEnumLike = false;

  // custom <class PodObject>

  PodObject(id, [this._fields]) : super(id) {
    _fields ??= [];
    _fields.forEach(_setOwner);
  }

  _setOwner(field) => field._owner = this;

  addField(PodField field) {
    _setOwner(field);
    _fields.add(field);
  }

  addAllFields(Iterable<PodField> fields) => fields.forEach((f) => addField(f));

  Iterable<PropertyError> _getPropertyErrors(
      UDT_PROPERTY, List<PropertyDefinitionSet> propertyDefinitionSets) {
    List<PropertyError> errors =
        super._getPropertyErrors(UDT_PROPERTY, propertyDefinitionSets);
    fields.forEach((field) =>
        errors.addAll(field.getPropertyErrors(propertyDefinitionSets)));
    return errors;
  }

  bool operator ==(other) =>
      identical(this, other) ||
      other is PodObject &&
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
        indentBlock(brCompact([
          '----- doc -----',
          doc ?? '',
          '----- properties -----',
          indentBlock(brCompact(mapProperties((pn, prop) => '$pn -> $prop'))),
          '----- fields -----',
          indentBlock(brCompact(fields))
        ]))
      ]);

  bool get hasArray => fields.any((pf) => pf.podType.isArray);
  bool get hasVariableArray => fields.any((pf) => pf.podType.isVariableArray);
  bool get hasFixedSizeArray => fields.any((pf) => pf.podType.isFixedSizeArray);
  bool get hasDefaultedField => fields.any((pf) => pf.defaultValue != null);

  Set<FieldPath> get fieldPaths {
    if (_fieldPaths == null) {
      _fieldPaths = new Set();
      _transitiveFields([], _fieldPaths);
    }
    return _fieldPaths;
  }

  _transitiveFields(List path, Set<FieldPath> paths) {
    for (PodField field in fields) {
      final fieldPath = new List.from(path)..add(field);
      if (field.podType is PodObject) {
        final po = field.podType;
        po._transitiveFields(fieldPath, paths);
      } else if (field.podType is PodMapType) {
        final PodMapType podMapType = field.podType;
        final valueType = podMapType.valueReferredType;
        final mapValuePath = new List.from(fieldPath)..add(null);
        if (valueType is PodObject) {
          final po = valueType;
          po._transitiveFields(mapValuePath, paths);
        }
      }
      paths.add(new FieldPath(fieldPath));
    }
  }

  // end <class PodObject>

  List<PodField> _fields = [];
  Set<FieldPath> _fieldPaths;
}

/// Package names are effectively a list of Id isntances.
///
/// They can be constructed from and represented by the common dotted form:
///
///    [ id('dossier'), id('common') ] => 'dossier.common'
///
///    [ id('dossier'), id('balance_sheet') ] => 'dossier.balance_sheet'
class PackageName {
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is PackageName && const ListEquality().equals(_path, other._path));

  @override
  int get hashCode => const ListEquality<Id>().hash(_path ?? const []).hashCode;

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
  toString() => path.map((id) => id.snake).join('.');

  asId() => new Id(path.map((id) => id.snake).join('_'));

  // end <class PackageName>

  List<Id> _path = [];
}

/// Package structure to support organization of pod definitions
class PodPackage extends Entity with PropertySet {
  /// Name of package
  PackageName get packageName => _packageName;

  /// Packages required by (ie containing referenced types) this package
  List<PodPackage> get imports => _imports;

  /// Named constants within the package
  List<PodConstant> get podConstants => _podConstants;

  /// Any properties associated with this type
  List<PropertyDefinitionSet> get propertyDefinitionSets =>
      _propertyDefinitionSets;

  // custom <class PodPackage>

  PodPackage(packageName,
      {List<PropertyDefinitionSet> propertyDefinitionSets,
      Iterable<PodPackage> imports,
      Iterable<PodConstant> podConstants,
      Iterable<PodType> namedTypes}) {
    this.packageName = packageName;
    this._propertyDefinitionSets = propertyDefinitionSets ?? [];
    imports ??= [];
    _imports
      ..addAll(imports)
      ..addAll(concat(imports.map((PodPackage pkg) => pkg.imports)));
    this._podConstants = podConstants ?? [];

    {
      namedTypes ??= [];

      // Get all named types recursively
      namedTypes.forEach((var t) {
        final qn = qualifiedName(t.id.snake);
        if (_namedTypesMap.containsKey(qn)) {
          throw "Duplicate type in pod package: $qn";
        }
        _namedTypesMap[qn] = t;
        _localNamedTypesMap[qn] = t;
      });
      this._imports.forEach(
          (PodPackage import) => _namedTypesMap.addAll(import._namedTypesMap));
    }

    _allTypes = visitTypes(null);
    _checkNamedTypes();
  }

  get id => _packageName.asId();

  get name => _packageName.toString();

  Iterable<Entity> get children => Iterable.empty();

  qualifiedName(s) => '$name.$s';

  get namedTypes => _namedTypesMap.values;
  get namedTypesNames => _namedTypesMap.keys;
  get localNamedTypes => _localNamedTypesMap.values;

  get podMaps => concat(podObjects.map((PodObject po) => po.fields
      .map((PodField field) => field.podType)
      .whereType<PodMapType>()
      .map((mapType) => mapType)));

  Iterable<PropertyError> get propertyErrors =>
      getPropertyErrors(_propertyDefinitionSets);

  Iterable<PropertyError> getPropertyErrors(
          List<PropertyDefinitionSet> propertyDefinitionSets) =>
      _getPropertyErrors(PACKAGE_PROPERTY, propertyDefinitionSets);

  Iterable<PropertyError> _getPropertyErrors(
      propertyType, List<PropertyDefinitionSet> propertyDefinitionSets) {
    List<PropertyError> errors =
        super._getPropertyErrors(propertyType, propertyDefinitionSets);
    allTypes.where((t) => t is PodUserDefinedType).forEach(
        (t) => errors.addAll(t.getPropertyErrors(propertyDefinitionSets)));
    return errors;
  }

  set imports(Iterable imports) {
    this._imports = imports;
  }

  set packageName(packageName) {
    this._packageName = new PackageName(packageName);
  }

  PodType getType(String typeName) =>
      allTypes.firstWhere((t) => t.typeName == typeName, orElse: () => null);

  PodType getFieldType(String objectName, String fieldName) {
    final podType = getType(objectName) as PodObject;
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

  Iterable<PodObject> get podObjects => namedTypes.whereType<PodObject>();
  Iterable<PodEnum> get podEnums => namedTypes.whereType<PodEnum>();

  Iterable<PodObject> get localPodObjects =>
      localNamedTypes.whereType<PodObject>();
  Iterable<PodEnum> get localPodEnums => localNamedTypes.whereType<PodEnum>();
  Iterable<PodMapType> get localPodMaps =>
      localNamedTypes.whereType<PodMapType>();

  get localPodFields => concat(localPodObjects.map((PodObject o) => o.fields));

  visitTypes(func(PodType)) {
    Set visitedTypes = new Set();

    visitType(podType) {
      _logger.info('Visiting ${podType.typeName}');

      assert(podType != null);
      if (podType is PodTypeRef) {
        podType._resolvedType = _resolveType(podType);
        visitType(podType._resolvedType);
      } else if (podType is PodArrayType) {
        if (podType._referredType is PodTypeRef) {
          podType.referredType = _resolveType(podType._referredType);
        }
        visitType(podType.referredType);
      } else if (podType is PodMapType) {
        if (podType._keyReferredType is PodTypeRef) {
          podType.keyReferredType = _resolveType(podType._keyReferredType);
        }
        visitType(podType.keyReferredType);
        if (podType._valueReferredType is PodTypeRef) {
          podType.valueReferredType = _resolveType(podType._valueReferredType);
        }
        visitType(podType.valueReferredType);
      } else {
        if (!visitedTypes.contains(podType)) {
          if (podType is PodObject) {
            for (var field in (podType as PodObject).fields) {
              visitType(field._podType);
            }
          }

          if (func != null) func(podType);
          visitedTypes.add(podType);
        }
      }
    }

    for (var podType in namedTypes) {
      visitType(podType);
    }
    return visitedTypes;
  }

  _resolveType(PodTypeRef podTypeRef) {
    var found;
    if (podTypeRef.packageName.isQualified) {
      _logger.info('Look for $podTypeRef in imported packages');
      final package = imports.firstWhere(
          (package) => package.packageName == podTypeRef.packageName,
          orElse: () => null);
      try {
        found = package._findNamedType(podTypeRef.typeName);
      } catch (e) {
        throw "PodPackage($name) no ${podTypeRef.typeName} in ${namedTypes.map((t) => t.typeName)}";
      }
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

  _findNamedType(typeName) {
    try {
      return namedTypes.firstWhere((t) => t.typeName == typeName,
          orElse: () => throw "Could not find type ${typeName} in named types "
              "${namedTypes.map((nt) => nt.id).join(', ')}");
    } catch (e) {
      throw 'Could not find single matching type $typeName - excp: $e';
    }
  }

  toString() => brCompact([
        'PodPackage($name)',
        '----- properties -----',
        indentBlock(brCompact(mapProperties((pn, prop) => '$pn -> $prop'))),
        '----- pod constants -----',
        indentBlock(br(podConstants.map((t) => t.toString()))),
        '----- all types -----',
        indentBlock(
            brCompact(allTypes.map((t) => '${t.runtimeType}(${t.typeName})')))
      ]);

  get details => brCompact([
        'PodPackage($name)',
        '--------- imports ---------',
        indentBlock(br(imports.map((t) => t.toString()))),
        '--------- podConstants ---------',
        indentBlock(br(podConstants.map((t) => t.toString()))),
        '--------- allTypes ---------',
        indentBlock(br(allTypes.map((t) => t.toString()),
            '\n----------------------------------\n'))
      ]);

  _checkNamedTypes() {
    if (!namedTypes.every((namedType) =>
        namedType is PodObject ||
        namedType is PodEnum ||
        namedType is PodPredefinedType)) {
      throw new ArgumentError(
          'PodPackage named types must be PodObjects or named PodEnums');
    }
    final unique = new Set();
    final duplicate =
        allTypes.firstWhere((t) => !unique.add(t.typeName), orElse: () => null);
    if (duplicate != null) {
      throw new ArgumentError(
          'PodPackage named types must be unique - duplicate: $duplicate');
    }
  }

  get toLiteral {}

  // end <class PodPackage>

  PackageName _packageName;
  List<PodPackage> _imports = [];
  List<PodConstant> _podConstants = [];

  /// The named and therefore referencable types within the package
  Map<String, PodType> _localNamedTypesMap = {};

  /// The named and therefore referencable types within the package including imported types
  Map<String, PodType> _namedTypesMap = {};

  /// All types within the package including *anonymous* types
  Set _allTypes;
  List<PropertyDefinitionSet> _propertyDefinitionSets = [];
}

class CharType extends FixedSizeType {
  CharType._() : super(new Id('char')) {}

  toString() => id.capCamel;
}

class DoubleType extends FixedSizeType {
  DoubleType._() : super(new Id('double')) {}

  toString() => id.capCamel;
}

class ObjectIdType extends FixedSizeType {
  ObjectIdType._() : super(new Id('object_id')) {}

  toString() => id.capCamel;
}

class BooleanType extends FixedSizeType {
  BooleanType._() : super(new Id('boolean')) {}

  toString() => id.capCamel;
}

class DateType extends FixedSizeType {
  DateType._() : super(new Id('date')) {}

  toString() => id.capCamel;
}

class RegexType extends FixedSizeType {
  RegexType._() : super(new Id('regex')) {}

  toString() => id.capCamel;
}

class Int8Type extends FixedSizeType {
  Int8Type._() : super(new Id('int8')) {}

  toString() => id.capCamel;
}

class Int16Type extends FixedSizeType {
  Int16Type._() : super(new Id('int16')) {}

  toString() => id.capCamel;
}

class Int32Type extends FixedSizeType {
  Int32Type._() : super(new Id('int32')) {}

  toString() => id.capCamel;
}

class Int64Type extends FixedSizeType {
  Int64Type._() : super(new Id('int64')) {}

  toString() => id.capCamel;
}

class Uint8Type extends FixedSizeType {
  Uint8Type._() : super(new Id('uint8')) {}

  toString() => id.capCamel;
}

class Uint16Type extends FixedSizeType {
  Uint16Type._() : super(new Id('uint16')) {}

  toString() => id.capCamel;
}

class Uint32Type extends FixedSizeType {
  Uint32Type._() : super(new Id('uint32')) {}

  toString() => id.capCamel;
}

class Uint64Type extends FixedSizeType {
  Uint64Type._() : super(new Id('uint64')) {}

  toString() => id.capCamel;
}

class DateTimeType extends FixedSizeType {
  DateTimeType._() : super(new Id('date_time')) {}

  toString() => id.capCamel;
}

class TimestampType extends FixedSizeType {
  TimestampType._() : super(new Id('timestamp')) {}

  toString() => id.capCamel;
}

class UuidType extends FixedSizeType {
  UuidType._() : super(new Id('uuid')) {}

  toString() => id.capCamel;
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
final UuidArray = array(Timestamp, doc: 'Array<Uuid>');

PodEnum enum_(id, [values]) => new PodEnum(makeId(id), values);

PodConstant constant(id, podType, value) =>
    new PodConstant(makeId(id), podType, value);

PodField field(id, [podType]) =>
    new PodField(makeId(id), podType == null ? Str : podType);

PodField anonymousField(podType) => new PodField(makeId(podType), podType);

PodObject object(id, [fields]) => new PodObject(makeId(id), fields);

BitSetType bitSet(id, numBits, {rhsPadBits, lhsPadBits}) =>
    new BitSetType(id, numBits, rhsPadBits: rhsPadBits, lhsPadBits: lhsPadBits);

/// Convenience function for creating a field with same id as bitSet
///
/// BitSets are modeled as types which must be named. Fields also require a name
/// which is almost always the name of the bitset. This function allows:
///
///     bitSetField('io_flags', 4)
///
///
PodField bitSetField(id, numBits, {rhsPadBits, lhsPadBits}) => new PodField(
    makeId(id),
    bitSet(id, numBits, rhsPadBits: rhsPadBits, lhsPadBits: lhsPadBits));

/// Creates a PodArrayType from [referencedType] with optional [doc] and
/// [maxLength].
PodArrayType array(dynamic referredType, {doc, dynamic maxLength}) =>
    new PodArrayType(referredType, doc: doc, maxLength: maxLength);

PodPredefinedType podPredefinedType(id) => new PodPredefinedType(id);

PodMapType map(dynamic keyReferredType, dynamic valueReferredType, {doc}) =>
    new PodMapType(keyReferredType, valueReferredType, doc: doc);

PodMapType strMap(dynamic valueReferredType, {doc}) =>
    new PodMapType(Str, valueReferredType, doc: doc);

StrType fixedStr(int maxLength) => new StrType(maxLength);

PodPackage package(packageName,
        {propertyDefinitionSets, imports, namedTypes}) =>
    new PodPackage(packageName,
        propertyDefinitionSets: propertyDefinitionSets,
        imports: imports,
        namedTypes: namedTypes);

Id _makeValidIdPart(part) => makeId(part);
List<Id> _makeValidPath(Iterable<dynamic> path) =>
    path.map(_makeValidIdPart).toList();

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

_makePrefixedTypeId(prefix, maxLength) => makeId(maxLength == null
    ? prefix
    : maxLength is int
        ? '${prefix}_of_${maxLength}'
        : '${prefix}_of_${maxLength.encodedId.snake}');

_referredTypeId(t) => t is String ? makeId(t.replaceAll('.', '_')) : t.id;

_normalizeReferredType(referredType) => (referredType is PodType ||
        referredType is PodTypeRef)
    ? referredType
    : referredType is String
        ? new PodTypeRef.fromQualifiedName(referredType)
        : throw new ArgumentError(
            'PodArray<referredType> can only be assigned PodType, PodTypeRef, String - qualified pod name'
            '- not ${referredType.runtimeType}');

EnumValue ev(id, [doc]) => new EnumValue(id, doc);

// end <library ebisu_pod>

final Char = new CharType._();
final Double = new DoubleType._();
final ObjectId = new ObjectIdType._();
final Boolean = new BooleanType._();
final Date = new DateType._();
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
final Uuid = new UuidType._();
