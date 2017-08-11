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
      _module = new Module(this.package.id);

      final podObjects = _package.allTypes.where((t) => t is PodObject);
      final podEnums = _package.allTypes.where((t) => t is PodEnum);

      podEnums.forEach((pe) {
        _module.enums.add(_makeEnum(pe));
      });

      final uniqueStrMaps = new Set();
      package.podMaps.forEach((PodMapType pmt) {
        if (pmt.keyReferredType is StrType) {
          final valueType = _mapFieldType(pmt.valueReferredType);
          if (!uniqueStrMaps.contains(valueType)) {
            _module.typeAliases.add(ebisu_rs.typeAlias(
                'map_of_str_to_${pmt.valueReferredType.id.snake}',
                'HashMap<String, $valueType>'));
            uniqueStrMaps.add(valueType);
          }
        } else if (pmt.keyReferredType is PodEnum) {
          _logger.info('Found key of enum type ${pmt.keyReferredType.id}');
        }
      });

      podObjects.forEach((PodObject po) {
        _module.structs.add(_makeStruct(po));
      });
    }
    return _module;
  }

  static final _rustTypeMap = {
    'char': ebisu_rs.char,
    'date': 'chrono::Date<chrono::Utc>',
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

  final _strNameRe = new RegExp(r'^str_(\d+)$');

  _makeMember(PodObject po, PodField field) => field.podType.isArray
      ? _makeArrayMember(field)
      : (_makeField(field)..type = _mapFieldType(field.podType));

  _makeField(PodField field) => ebisu_rs.field(field.id)..doc = field.doc;

  _makeArrayMember(PodField field) {
    var rustType = _mapFieldType(field.podType);

    return _makeField(field)
      ..doc = field.doc
      ..type = field.podType?.maxLength == null
          ? 'Vec<$rustType>'
          : '[$rustType, ${field.podType.maxLength}]';
  }

  _mapFieldType(PodType podType) {
    final podTypeName = podType is PodArrayType
        ? _mapFieldType(podType.referredType)
        : _rustTypeMap[podType.id.snake];
    return podTypeName ?? podType.id.capCamel;
  }

  _makeEnum(PodEnum pe) =>
      ebisu_rs.enum_(pe.id, pe.values.map((e) => e.id.snake))
        ..doc = pe.doc
        ..derive = [ebisu_rs.Debug];

  _makeStruct(PodObject po) => ebisu_rs.struct(po.id)
    ..doc = po.doc
    ..derive = [
      ebisu_rs.Debug,
      ebisu_rs.Clone,
      ebisu_rs.Serialize,
      ebisu_rs.Deserialize
    ]
    ..fields.addAll(po.fields.map((PodField field) => _makeMember(po, field)));

  // end <class PodRustMapper>

  PodPackage _package;

  /// Module to insert rust mappings
  Module _module;
}

// custom <library pod_rust>
// end <library pod_rust>
