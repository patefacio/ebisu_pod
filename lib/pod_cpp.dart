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
  Napespace get namespace => _namespace;

  // custom <class PodCppMapper>

  get header {
    if (_header == null) {
      final path = package.name.path;
      final podObjects = _package.namedTypes.where((t) => t is PodObject);
      final podEnums = _package.namedTypes.where((t) => t is PodEnum);
      final ns = new Namespace(path.sublist(0, path.length - 1));
      _header = new Header(path.last)
        ..namespace = ns
        ..classes = podObjects.map(_makeClass)
        ..enums = podEnums.map(_makeEnum);

    }
    return _header;
  }

  _makeClass(PodObject po) {
    final result = new Class(po.id)
      ..isStreamable = true
      ..usesStreamers = po.hasArray;
    result.members = po.fields.map((f) => _makeMember(po, f));
    return result;
  }

  _makeEnum(PodEnum pe) => new Enum(pe.id)
    ..isStreamable = true
    ..values = pe.values;

  _makeMember(PodObject po, PodField field) =>
    new Member(field.id)..type = _cppType(package.getFieldType(po.id.snake, field.name));

  final _cppTypeMap = {
    'date' : 'boost::gregorian::date',
    'int' : 'int',
    'int32' : 'std::int32_t',
    'int64' : 'std::int64_t',
    'double': 'double',
    'str' : 'std::string',
    'boolean' : 'bool',
  };

  _cppType(PodType podType) {
    final podTypeName = podType.typeName;
    var cppType = _cppTypeMap[podTypeName];
    if(cppType == null) {
      cppType = defaultNamer.nameClass(podType.id);
    }
    return cppType;
  }


  // end <class PodCppMapper>

  PodPackage _package;
  Napespace _namespace;

  /// C++ header with all PodObject and PodEnum definitions
  Header _header;
}

// custom <library pod_cpp>
// end <library pod_cpp>
