/// Consistent mapping of *plain old data* to rust structs
library ebisu_pod.pod_rust;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu_rs/ebisu_rs.dart' as ebisu_rs;
import 'package:ebisu_rs/ebisu_rs.dart' show Module;
import 'package:logging/logging.dart';

// custom <additional imports>
// end <additional imports>

final Logger _logger = new Logger('pod_rust');

class PodRustMapper {
  PodRustMapper(this._package);

  /// Package to generate basic rust mappings for
  PodPackage get package => _package;

  // custom <class PodRustMapper>

  Module get module => _makeModule();

  Module _makeModule() {
    if (_module == null) {
      _module = new Module(_package.id)..doc = _package.doc;

      final podObjects = _package.allTypes.where((t) => t is PodObject);
      final podEnums = _package.allTypes.where((t) => t is PodEnum);
      final predefined = _package.allTypes.where((t) => t is PodPredefinedType);

      podEnums.forEach((pe) {
        _module.enums.add(_makeEnum(pe));
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
        final keyType = _mapFieldType(false, pmt.keyReferredType);
        final valueType = _mapFieldType(false, pmt.valueReferredType);
        if (!uniqueMaps.contains(valueType)) {
          _module.typeAliases.add(ebisu_rs.pubTypeAlias(
              uniqueKey, 'HashMap<$keyType, $valueType>'));
          uniqueMaps.add(valueType);
          requiresHashMap = true;
        }
      });

      if (requiresHashMap) {
        _module.uses.add(ebisu_rs.use('std::collections::HashMap'));
      }

      podObjects.forEach((PodObject po) {
        _module.structs.add(_makeStruct(po));
      });
    }
    return _module;
  }

  static final _rustTypeMap = {
    'char': ebisu_rs.char,
    'date': 'chrono::NaiveDate',
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
        ..type = _mapFieldType(field.isOptional, field.podType));

  _makeField(PodField field) => ebisu_rs.pubField(field.id)..doc = field.doc;

  _makeArrayMember(PodField field) {
    var rustType = _mapFieldType(field.isOptional, field.podType);

    return _makeField(field)
      ..doc = field.doc
      ..type = field.podType?.maxLength == null
          ? 'Vec<$rustType>'
          : '[$rustType, ${field.podType.maxLength}]';
  }

  _mapFieldType(bool isOptional, PodType podType) => isOptional
      ? 'Option<${_mapFieldTypeBase(podType)}>'
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
    ..derive = [
      ebisu_rs.Debug,
      ebisu_rs.Clone,
      ebisu_rs.Copy,
      ebisu_rs.Eq,
      ebisu_rs.PartialEq,
      ebisu_rs.Hash,
      ebisu_rs.Serialize,
      ebisu_rs.Deserialize
    ];

  _makeStruct(PodObject po) => ebisu_rs.pubStruct(po.id)
    ..doc = po.doc
    ..derive = [
      ebisu_rs.Debug,
      ebisu_rs.Clone,
      ebisu_rs.Serialize,
      ebisu_rs.Deserialize
    ]
    ..fields.addAll(po.fields.map((PodField field) => _makeMember(field)));

  // end <class PodRustMapper>

  PodPackage _package;

  /// Module to insert rust mappings
  Module _module;
}

// custom <library pod_rust>
// end <library pod_rust>
