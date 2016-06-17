/// Consistent mapping of *plain old data* to C++ structs
library ebisu_pod.pod_cpp;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_cpp/ebisu_cpp.dart' as ebisu_cpp show EnumValue;
import 'package:ebisu_cpp/ebisu_cpp.dart' hide EnumValue;
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:id/id.dart';
import 'package:quiver/iterables.dart';

// custom <additional imports>
// end <additional imports>

/// Given a pod package, maps the data definitions to C++
class PodCppMapper {
  PodCppMapper(this._package);

  /// Package to generate basic C++ mappings for
  PodPackage get package => _package;

  /// Napespace into which to place the type hierarchy
  Namespace get namespace => _namespace;

  // custom <class PodCppMapper>

  get header {
    if (_header == null) {
      final path = package.packageName.path;
      final podObjects = _package.allTypes.where((t) => t is PodObject);
      final podEnums = _package.allTypes.where((t) => t is PodEnum);
      final fixedStrTypes = new Set.from(concat(podObjects.map((po) => po.fields
          .map((field) => field.podType)
          .where((pt) => pt is StrType && pt.isFixedSize))));

      final ns = new Namespace(path);
      _header = new Header(path.last)..namespace = ns;

      if (fixedStrTypes.isNotEmpty) {
        header
          ..includes.add('ebisu/utils/fixed_size_char_array.hpp')
          ..usings.addAll(fixedStrTypes.map((fst) => using(fst.typeName,
              'ebisu::utils::Fixed_size_char_array<${fst.maxLength}>')));
      }

      _header
        ..classes = podObjects.map(_makeClass).toList()
        ..enums = podEnums.map(_makeEnum).toList();

      for (var type in _package.allTypes) {
        if (type is DateType) {
          _header.includes.add('boost/date_time/gregorian/gregorian.hpp');
        }
        if (type.isVariableArray) {
          _addVectorIncludes(_header.includes);
        } else if (type.isFixedSizeArray) {
          _addArrayIncludes(_header.includes);
        }
      }
    }
    return _header;
  }

  _addVectorIncludes(l) =>
      l.addAll(['ebisu/utils/streamers/vector.hpp', 'vector']);
  _addArrayIncludes(l) =>
      l.addAll(['ebisu/utils/streamers/array.hpp', 'array']);

  _makeClass(PodObject po) {
    final result = new Class(po.id)
      ..doc = po.doc
      ..isStruct = true
      ..isStreamable = true
      ..usesStreamers = po.hasArray;
    if (po.hasVariableArray) {
      _addVectorIncludes(result.includes);
    }
    if (po.hasFixedSizeArray) {
      _addArrayIncludes(result.includes);
    }
    result.members = po.fields.map((f) => _makeMember(po, f)).toList();
    return result;
  }

  _makeEnum(PodEnum pe) => new Enum(pe.id)
    ..isStreamable = true
    ..isClass = true
    ..values =
        pe.values.map((ev) => new ebisu_cpp.EnumValue(ev.id)..doc = ev.doc);

  _makeMember(PodObject po, PodField field) => field.podType.isArray
      ? _makeArrayMember(po, field)
      : field.podType is BitSetType
          ? new BitSet(field.id, field.podType.numBits)
          : _makeScalarMember(po, field);

  _makeScalarMember(PodObject po, PodField field) {
    var cppType = _cppType(field.podType);
    final cppMember = new Member(field.id)
      ..cppAccess = public
      ..type = cppType;

    if (field.podType is StrType) {
      cppMember.isByRef = true;
    }
    if (field.defaultValue != null) {
      cppMember.init = field.defaultValue;
    }
    return cppMember;
  }

  _makeArrayMember(PodObject po, PodField field) {
    var cppType = _cppType(field.podType);

    return new Member(field.id)
      ..cppAccess = public
      ..isByRef = true
      ..type = field.podType?.maxLength == null
          ? 'std::vector<$cppType>'
          : 'std::array<$cppType, ${field.podType.maxLength}>';
  }

  final _cppTypeMap = {
    'char': 'char',
    'date': 'boost::gregorian::date',
    'regex': 'boost::regex',
    'int': 'int',
    'int8': 'std::int8_t',
    'int16': 'std::int16_t',
    'int32': 'std::int32_t',
    'int64': 'std::int64_t',
    'uint': 'uint',
    'uint8': 'std::uint8_t',
    'uint16': 'std::uint16_t',
    'uint32': 'std::uint32_t',
    'uint64': 'std::uint64_t',
    'double': 'double',
    'str': 'std::string',
    'boolean': 'bool',
  };

  final _strNameRe = new RegExp(r'^str_(\d+)$');

  _cppType(PodType podType) {
    final podTypeName = podType is PodArrayType
        ? podType.referredType.id.snake
        : podType.typeName;
    var cppType = _cppTypeMap[podTypeName];
    if (cppType == null) {
      final strMatch = _strNameRe.firstMatch(podTypeName);
      if (strMatch != null) {
        cppType = '${makeId(podTypeName).capSnake}_t';
      } else {
        cppType = defaultNamer.nameClass(makeId(podTypeName));
      }
    }
    return cppType;
  }

  // end <class PodCppMapper>

  PodPackage _package;
  Namespace _namespace;

  /// C++ header with all PodObject and PodEnum definitions
  Header _header;
}

// custom <library pod_cpp>
main() => print('done');
// end <library pod_cpp>
