/// Consistent mapping of *plain old data* to rust structs
library ebisu_pod.pod_rust;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu_rs/ebisu_rs.dart' as ebisu_rs;
import 'package:ebisu_rs/ebisu_rs.dart' show Module;
import 'package:logging/logging.dart';

// custom <additional imports>

import 'package:ebisu_rs/common_traits.dart';
import 'package:id/id.dart';

// end <additional imports>

final Logger _logger = new Logger('pod_rust');

class PodRustMapper {
  PodRustMapper(this._package);

  /// Package to generate basic rust mappings for
  PodPackage get package => _package;

  /// List of derives to be applied to objects
  List<ebisu_rs.Derivable> objectDerives = [
    ebisu_rs.Debug,
    ebisu_rs.Clone,
    ebisu_rs.Serialize,
    ebisu_rs.Deserialize,
    ebisu_rs.Default
  ];

  /// List of derives to be applied to enumerations
  List<ebisu_rs.Derivable> enumDerives = [
    ebisu_rs.Debug,
    ebisu_rs.Clone,
    ebisu_rs.Copy,
    ebisu_rs.Eq,
    ebisu_rs.PartialEq,
    ebisu_rs.Hash,
    ebisu_rs.Serialize,
    ebisu_rs.Deserialize
  ];

  // custom <class PodRustMapper>

  Module get module => _makeModule();

  Module _makeModule() {
    if (_module == null) {
      _module = new Module(_package.id)
        ..doc = _package.doc
        ..moduleCodeBlock(ebisu_rs.moduleBottom);

      final podObjects = _package.allTypes.where((t) => t is PodObject);
      final podEnums = _package.allTypes.where((t) => t is PodEnum);
      final predefined = _package.allTypes.where((t) => t is PodPredefinedType);

      podEnums.forEach((pe) {
        final e = _makeEnum(pe);
        _module.enums.add(e);
        final imp = ebisu_rs.traitImpl(defaultTrait, e.unqualifiedName);
        imp.functions.first.codeBlock
          ..tag = null
          ..snippets.add('${e.unqualifiedName}::${e.variants.first.name}');
        _module.impls.add(imp);
      });

      predefined.forEach((PodPredefinedType ppt) {
        final prop = ppt.getProperty('rust_aliased_to');
        if (prop != null) {
          _module.typeAliases.add(ebisu_rs.pubTypeAlias(ppt.id, prop));
        }
      });

      final uniqueMaps = new Set();
      bool requiresHashMap = false;

      package.podMaps.forEach((PodMapType pmt) {
        final uniqueKey = pmt.id.capCamel;
        final keyType = _mapFieldType(pmt.keyReferredType);
        final valueType = _mapFieldType(pmt.valueReferredType);
        if (!uniqueMaps.contains([keyType, valueType])) {
          _module.typeAliases.add(ebisu_rs.pubTypeAlias(
              uniqueKey, 'HashMap<$keyType, $valueType>'));
          uniqueMaps.add([keyType, valueType]);
          requiresHashMap = true;
        }
      });

      if (requiresHashMap) {
        _module.uses.add(ebisu_rs.use('std::collections::HashMap'));
      }

      podObjects.forEach((PodObject po) {
        _module.structs.add(_makeStruct(po));
        final rustHasImpl = po.getProperty('rust_has_impl');
        if (rustHasImpl ?? false) {
          _module.impls
              .add(ebisu_rs.typeImpl(_module.structs.last.genericName));
        }
        final List rustDerives = po.getProperty('rust_derives');
        if (rustDerives != null) {
          _module.structs.last.derive.addAll(rustDerives);
        }

        final List rustNotDerives = po.getProperty('rust_not_derives');
        if (rustNotDerives != null) {
          final remove = rustNotDerives.map((d) => ebisu_rs.Derivable.fromString(d)).toList();
          _module.structs.last.derive.removeWhere((d) => remove.contains(d));
        }
      });
    }
    return _module;
  }

  static final _rustTypeMap = {
    'char': ebisu_rs.char,
    'date': 'Date',
    'date_time': 'chrono::DateTime<chrono::Utc>',
    'regex': 'regex::Regex',
    'int': ebisu_rs.i64,
    'int8': ebisu_rs.i8,
    'int16': ebisu_rs.i16,
    'int32': ebisu_rs.i32,
    'int64': ebisu_rs.i64,
    'uint': ebisu_rs.u64,
    'uint8': ebisu_rs.u8,
    'uint16': ebisu_rs.u16,
    'uint32': ebisu_rs.u32,
    'uint64': ebisu_rs.u64,
    'double': ebisu_rs.f64,
    'str': ebisu_rs.string,
    'boolean': ebisu_rs.bool_,
    'timestamp': 'chrono::DateTime<chrono::Utc>',
  };

  _makeMember(PodField field) => field.podType.isArray
      ? _makeArrayMember(field)
      : (_makeField(field)
        ..type = _addOption(field));

  _makeField(PodField field) => ebisu_rs.pubField(field.id)..doc = field.doc;

  _makeArrayMember(PodField field) {
    return _makeField(field)
      ..doc = field.doc
      ..type = _addOption(field);
  }

  _addOption(PodField field) => field.isOptional ? 'Option<${_mapFieldType(field.podType)}>' : _mapFieldType(field.podType);

  _mapFieldType(PodType podType) => 
      podType is PodArrayType? (
        podType.maxLength == null
          ? 'Vec<${_mapFieldTypeBase(podType)}>' 
          : '[${_mapFieldTypeBase(podType)} , ${podType.maxLength}]')
      : _mapFieldTypeBase(podType);

  _mapFieldTypeBase(PodType podType) {
    final podTypeName = podType is PodArrayType
        ? _mapFieldTypeBase(podType.referredType)
        : _rustTypeMap[podType.id.snake];
    return podTypeName ?? podType.id.capCamel;
  }

  _makeEnum(PodEnum pe) => ebisu_rs.pubEnum(
      pe.id, pe.values.map((e) => ebisu_rs.uv(e.id.snake)..doc = e.doc))
    ..doc = pe.doc
    ..derive = new List.from(enumDerives);

  _makeStruct(PodObject po) => ebisu_rs.pubStruct(po.id)
    ..doc = po.doc
    ..derive = new List.from(objectDerives)
    ..fields.addAll(po.fields.map((PodField field) => _makeMember(field)));

  // end <class PodRustMapper>

  PodPackage _package;

  /// Module to insert rust mappings
  Module _module;
}

// custom <library pod_rust>
// end <library pod_rust>
