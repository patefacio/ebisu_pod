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
        ..classes = podObjects.map((po) => new Class(po.id))
        ..enums = podEnums.map((e) => new Enum(e.id));

    }
    return _header;
  }

  // end <class PodCppMapper>

  PodPackage _package;
  Napespace _namespace;

  /// C++ header with all PodObject and PodEnum definitions
  Header _header;
}

// custom <library pod_cpp>
// end <library pod_cpp>
