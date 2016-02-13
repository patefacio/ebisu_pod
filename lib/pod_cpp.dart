/// Consistent mapping of *plain old data* to C++ structs
library ebisu_pod.pod_cpp;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:id/id.dart';

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
      final path = package.name.path;
      final podObjects = _package.allTypes.where((t) => t is PodObject);
      final podEnums = _package.allTypes.where((t) => t is PodEnum);
      final ns = new Namespace(path);
      _header = new Header(path.last)..namespace = ns;

      _header
        ..classes = podObjects.map(_makeClass).toList()
        ..enums = podEnums.map(_makeEnum).toList();

      for (var type in _package.allTypes) {
        if (type is DateType) {
          _header.includes.add('boost/date_time/gregorian/gregorian.hpp');
        }
        if (type.isArray) {
          _header.includes.add('ebisu/utils/streamers/vector.hpp');
        }
      }
    }
    return _header;
  }

  _makeClass(PodObject po) {
    final result = new Class(po.id)
      ..isStruct = true
      ..isStreamable = true
      ..usesStreamers = po.hasArray;
    if (po.hasArray) {
      result.includes.add('ebisu/utils/streamers/vector.hpp');
    }
    result.members = po.fields.map((f) => _makeMember(po, f)).toList();
    return result;
  }

  _makeEnum(PodEnum pe) => new Enum(pe.id)
    ..isStreamable = true
    ..isClass = true
    ..values = pe.values;

  _makeMember(PodObject po, PodField field) => field.podType.isArray
      ? _makeArrayMember(po, field)
      : _makeScalarMember(po, field);

  _makeScalarMember(PodObject po, PodField field) {
    var cppType = _cppType(field.podType);
    return new Member(field.id)
      ..cppAccess = public
      ..type = cppType;
  }

  _makeArrayMember(PodObject po, PodField field) {
    var cppType = _cppType(field.podType);
    return new Member(field.id)
      ..cppAccess = public
      ..isByRef = true
      ..type = 'std::vector<$cppType>';
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

  _cppType(PodType podType) {
    final podTypeName = podType is PodArrayType
        ? podType.referredType.id.snake
        : podType.typeName;
    var cppType = _cppTypeMap[podTypeName];
    if (cppType == null) {
      cppType = defaultNamer.nameClass(makeId(podTypeName));
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
// end <library pod_cpp>
