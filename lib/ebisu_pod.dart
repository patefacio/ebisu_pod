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

/// Indicates an attempt to access an invalid property
class PropertyError {
  const PropertyError(this.propertyType, this.itemAccessed, this.property);

  bool operator ==(PropertyError other) =>
      identical(this, other) ||
      propertyType == other.propertyType &&
          itemAccessed == other.itemAccessed &&
          property == other.property;

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
abstract class PropertySet {
  // custom <class PropertySet>

  Iterable get propertyNames => _properties.keys;

  mapProperties(f(propName, property)) =>
      propertyNames.map((pn) => f(pn, _properties[pn]));

  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      String field = MirrorSystem.getName(invocation.memberName);
      final prop = _properties[field];
      return prop;
    } else if (invocation.isSetter &&
        invocation.positionalArguments.length == 1) {
      String field =
          MirrorSystem.getName(invocation.memberName).replaceAll('=', '');
      return (_properties[field] = invocation.positionalArguments.first);
    }
  }

  Iterable<String> getPropertyErrors(
      List<PropertyDefinitionSet> propertyDefinitionSets);

  Iterable<String> _getPropertyErrors(PropertyType propertyType,
      List<PropertyDefinitionSet> propertyDefinitionSets) {
    List errors = [];
    propertyNames.forEach((var propName) {
      final def = propertyDefinitionSets.firstWhere((var pds) {
        final found = pds
            .getPropertyDefinitions(propertyType)
            .any((var pd) => pd.id.camel == propName);
        return found;
      },
          orElse: () =>
              errors.add(new PropertyError(propertyType, name, propName)));
    });
    return errors;
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

  bool operator ==(PodType other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType && _id == other._id;

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

/// Base class for user defined types
abstract class PodUserDefinedType extends PodType with PropertySet {
  // custom <class PodUserDefinedType>

  PodUserDefinedType(id) : super(id);

  Iterable<String> getPropertyErrors(
          List<PropertyDefinitionSet> propertyDefinitionSets) =>
      _getPropertyErrors(UDT_PROPERTY, propertyDefinitionSets);

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

  bool operator ==(VariableSizeType other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          _id == other._id &&
          _maxLength == other._maxLength;

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
      : super(id),
        this.rhsPadBits = rhsPadBits ?? 0,
        this.lhsPadBits = lhsPadBits ?? 0 {}

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
      runtimeType == other.runtimeType && _referredType == other._referredType;

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

  PodType get keyReferredType => _keyReferredType is PodTypeRef
      ? _keyReferredType.podType
      : _keyReferredType;

  PodType get valueReferredType => _valueReferredType is PodTypeRef
      ? _valueReferredType.podType
      : _valueReferredType;

  set valueReferredType(dynamic referredType) =>
      _valueReferredType = _normalizeReferredType(referredType);

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

  Iterable<String> getPropertyErrors(
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

  /// Returns name of [PodObject] in *snake_case*
  String get name => _id.snake;

  Iterable<String> _getPropertyErrors(
      UDT_PROPERTY, List<PropertyDefinitionSet> propertyDefinitionSets) {
    List errors =
        super._getPropertyErrors(UDT_PROPERTY, propertyDefinitionSets);
    fields.forEach((field) =>
        errors.addAll(field.getPropertyErrors(propertyDefinitionSets)));
    return errors;
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
        doc ?? indentBlock(blockComment(doc)),
        '----- properties -----',
        indentBlock(brCompact(mapProperties((pn, prop) => '$pn -> $prop'))),
        '----- fields -----',
        indentBlock(brCompact(fields.map((pf) => [
              '${pf.id}:${pf.podType}',
              pf.doc == null ? null : blockComment(pf.doc)
            ])))
      ]);

  bool get hasArray => fields.any((pf) => pf.podType.isArray);
  bool get hasVariableArray => fields.any((pf) => pf.podType.isVariableArray);
  bool get hasFixedSizeArray => fields.any((pf) => pf.podType.isFixedSizeArray);
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
  toString() => path.map((id) => id.snake).join('.');

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

  /// The named and therefore referencable types within the package
  List<PodType> get namedTypes => _namedTypes;

  /// Any properties associated with this type
  List<PropertyDefinitionSet> get propertyDefinitionSets =>
      _propertyDefinitionSets;

  // custom <class PodPackage>

  PodPackage(packageName,
      {List<PropertyDefinitionSet> propertyDefinitionSets,
      Iterable imports,
      Iterable<PodConstant> podConstants,
      Iterable<PodType> namedTypes}) {
    this.packageName = packageName;
    this._propertyDefinitionSets = propertyDefinitionSets ?? [];
    this._imports = imports ?? [];
    this._podConstants = podConstants ?? [];
    this._namedTypes = namedTypes ?? [];
    _allTypes = visitTypes(null);
    _checkNamedTypes();
  }

  get name => _packageName.toString();

  Iterable<String> get propertyErrors =>
      getPropertyErrors(_propertyDefinitionSets);

  Iterable<String> getPropertyErrors(
          List<PropertyDefinitionSet> propertyDefinitionSets) =>
      _getPropertyErrors(PACKAGE_PROPERTY, propertyDefinitionSets);

  Iterable<String> _getPropertyErrors(
      propertyType, List<PropertyDefinitionSet> propertyDefinitionSets) {
    List errors =
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
          (package) => package.packageName == podTypeRef.packageName,
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

  PackageName _packageName;
  List<PodPackage> _imports = [];
  List<PodConstant> _podConstants = [];
  List<PodType> _namedTypes = [];

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

class NullType extends FixedSizeType {
  NullType._() : super(new Id('null')) {}

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

PodConstant constant(id, podType, value) =>
    new PodConstant(makeId(id), podType, value);

PodField field(id, [podType]) =>
    new PodField(makeId(id), podType == null ? Str : podType);

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

_makePrefixedTypeId(prefix, maxLength) => makeId(maxLength == null
    ? prefix
    : maxLength is int
        ? '${prefix}_of_${maxLength}'
        : '${prefix}_of_${maxLength.encodedId.snake}');

_referredTypeId(t) => t is String ? makeId(t) : t.id;

_normalizeReferredType(referredType) => (referredType is PodType ||
        referredType is PodTypeRef)
    ? referredType
    : referredType is String
        ? new PodTypeRef.fromQualifiedName(referredType)
        : throw new ArgumentError(
            'PodArray<referredType> can only be assigned PodType, PodTypeRef, String - qualified pod name'
            '- not ${referredType.runtimeType}');

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
