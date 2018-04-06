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
    ebisu_rs.PartialOrd,
    ebisu_rs.Ord,
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

      final podObjects = _package.localPodObjects.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final podEnums = _package.localPodEnums.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final predefined =
          _package.localNamedTypes.where((t) => t is PodPredefinedType);

      podEnums.forEach((pe) {
        final e = _makeEnum(pe);
        _module.enums.add(e);
        final imp = ebisu_rs.traitImpl(defaultTrait, e.unqualifiedName)
          ..codeBlock.tag = null;
        imp.functions.first.codeBlock
          ..tag = null
          ..snippets.add('${e.unqualifiedName}::${e.variants.first.name}');
        if (pe.getProperty('rust_has_snake_conversions') == true) {
          e.hasSnakeConversions = true;
        }
        if (pe.getProperty('rust_has_shout_conversions') == true) {
          e.hasShoutConversions = true;
        }
        _module.impls.add(imp);
      });

      predefined.forEach((PodPredefinedType ppt) {
        final prop = ppt.getProperty('rust_aliased_to');
        if (prop != null) {
          _module.typeAliases
              .add(ebisu_rs.pubTypeAlias(ppt.id, prop)..doc = ppt.doc);
        }
      });

      final uniqueMaps = new Set();
      bool requiresBTreeMap = false;

      package.podMaps.forEach((PodMapType pmt) {
        final uniqueKey = pmt.id.capCamel;
        final keyType = _mapFieldType(pmt.keyReferredType);
        final valueType = _mapFieldType(pmt.valueReferredType);

        if (!uniqueMaps.contains([keyType, valueType])) {
          _module.typeAliases.add(ebisu_rs.pubTypeAlias(
              uniqueKey, 'BTreeMap<$keyType, $valueType>'));
          uniqueMaps.add([keyType, valueType]);
          requiresBTreeMap = true;
        }
      });

      if (requiresBTreeMap) {
        _module.uses.add(ebisu_rs.use('std::collections::BTreeMap'));
      }

      bool requiresSerdeError = false;
      podObjects.forEach((PodObject po) {
        final newStruct = _makeStruct(po);
        final rustIsEncapsulated = po.getProperty('rust_is_encapsulated');
        if (rustIsEncapsulated ?? false) {
          newStruct.isEncapsulated = true;
        }
        final rustHasImpl = po.getProperty('rust_has_impl');
        if (rustHasImpl ?? false) {
          newStruct.impl;
        }
        final List rustDerives = po.getProperty('rust_derives');
        if (rustDerives != null) {
          newStruct.derive.addAll(rustDerives);
        }

        final List rustNotDerives = po.getProperty('rust_not_derives');
        if (rustNotDerives != null) {
          final remove = rustNotDerives
              .map((d) => ebisu_rs.Derivable.fromString(d))
              .toList();
          newStruct.derive.removeWhere((d) => remove.contains(d));
        }

        final rustHasYamlReader = po.getProperty('include_yaml_reader');
        if (rustHasYamlReader ?? false) {
          _module.import('serde_yaml');
          _module.import('serde');
          _module.importWithMacros('serde_derive');
          _module.importWithMacros('failure');
          addYamlReader(po);
          requiresSerdeError = true;
        }

        Module makeSubModule(id) {
          final newModule = new Module(id, ebisu_rs.ModuleType.fileModule)
            ..moduleCodeBlock(ebisu_rs.moduleBottom)
            ..doc = 'Module for pod object `${po.id.snake}`'
            ..uses.add(ebisu_rs.use('super::*'));
          _module.modules.add(newModule);
          return newModule;
        }

        Module findOrMakeSubModule(id) {
          Module otherModule =
              _module.modules.firstWhere((m) => m.id == id, orElse: () => null);
          if (otherModule == null) {
            otherModule = makeSubModule(id);
          }
          return otherModule;
        }

        final ownModule = po.getProperty('rust_own_module');
        final inModule = po.getProperty('rust_in_module');

        if (ownModule) {
          final module = findOrMakeSubModule(po.id);
          module.structs.add(newStruct);
          _module.uses.add(
              ebisu_rs.use('${po.id.snake}::${po.id.capCamel}')..isPub = true);
        } else if (inModule != null) {
          final id = makeId(inModule);
          final module = findOrMakeSubModule(id);
          module.structs.add(newStruct);
          _module.uses.add(
              ebisu_rs.use('${id.snake}::${po.id.capCamel}')..isPub = true);
        } else {
          _module.structs.add(newStruct);
        }
      });

      if (requiresSerdeError) {
        _module.structs.add(ebisu_rs.pubStruct('serde_yaml_error')
          ..derive = ['Fail', 'Debug']
          ..doc = 'Error encountered with `serde_yaml` serialization'
          ..attrs = [
            ebisu_rs.strAttr(
                'fail(display="Failed reading type: {} source: {:?} error: {:?}", rust_type, source, error)')
          ]
          ..fields = [
            ebisu_rs.field('rust_type')
              ..doc = 'Type that failed to serialize'
              ..type = 'String',
            ebisu_rs.field('source')
              ..doc = 'Source of failed data'
              ..type = 'String',
            ebisu_rs.field('error')
              ..doc = 'Underlying `serde_yaml` error'
              ..type = '::serde_yaml::Error'
          ]);
      }
    }
    return _module;
  }

  addYamlReader(PodObject po) => _module.functions.add(
          new ebisu_rs.Fn('read_${po.id.snake}_from_yaml_file', [
        ebisu_rs.parm('yaml_path', ebisu_rs.ref('::std::path::Path'))
          ..doc = 'Path to yaml file'
      ])
            ..isPub = true
            ..doc = 'Reads and parses a ${po.id.snake} object from a file path'
            ..body = '''
use ::std::io::Read;
use ::serde_yaml::from_str;
let mut yaml_file = ::std::fs::File::open(yaml_path)?;
let mut buffer = String::new();
yaml_file.read_to_string(&mut buffer)?;
from_str(&buffer).map_err(|e| SerdeYamlError{ rust_type: "${po.id.capCamel}".to_string(), source: yaml_path.to_string_lossy().into(), error: e }.into())
          '''
            ..returns =
                '::std::result::Result<${po.id.capCamel}, ::failure::Error>'
            ..returnDoc = 'Parsed ${po.id.capCamel}');

  _makeMember(PodField field) => field.podType.isArray
      ? _makeArrayMember(field)
      : (_makeField(field)..type = _addOption(field));

  _makeField(PodField field) {
    final result = ebisu_rs.pubField(field.id)..doc = field.doc;

    if (field.getProperty('rust_read_only') ?? false) {
      result.access = ebisu_rs.ro;
    }

    if (field.getProperty('rust_read_only_ref') ?? false) {
      result
        ..access = ebisu_rs.ro
        ..byRef = true;
    }

    return result;
  }

  _makeArrayMember(PodField field) {
    return _makeField(field)
      ..doc = field.doc
      ..type = _addOption(field);
  }

  _addOption(PodField field) => field.isOptional
      ? 'Option<${_mapFieldType(field.podType)}>'
      : _mapFieldType(field.podType);

  _mapFieldType(PodType podType) => podType is PodArrayType
      ? (podType.maxLength == null
          ? 'Vec<${_mapFieldTypeBase(podType)}>'
          : '[${_mapFieldTypeBase(podType)} , ${podType.maxLength}]')
      : _mapFieldTypeBase(podType);

  _mapFieldTypeBase(PodType podType) {
    final podTypeName = podType is PodArrayType
        ? _mapFieldTypeBase(podType.referredType)
        : simpleRustType(podType);
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

final _rustTypeMap = {
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

simpleRustType(PodType podType) => _rustTypeMap[podType.id.snake];

// end <library pod_rust>
