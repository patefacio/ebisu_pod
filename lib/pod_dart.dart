/// Consistent mapping of pod to dart classes
library ebisu_pod.pod_dart;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu/ebisu_dart_meta.dart';
import 'package:ebisu_pod/ebisu_pod.dart';

// custom <additional imports>
// end <additional imports>

/// Given pod package maps definitions to dart classes/libraries
class PodDartMapper {
  PodDartMapper(this._package);

  /// Package to generate dart code for
  PodPackage get package => _package;

  // custom <class PodDartMapper>

  List<Library> createLibraries() {
    final result =
        package.imports.fold([], (prev, pkg) => prev..add[_createLibrary(pkg)]);
    result.add(_createLibrary(package));
    return result;
  }

  Library _createLibrary(PodPackage package) {
    final path = package.packageName.path;
    final podObjects = _package.allTypes.where((t) => t is PodObject);
    final podEnums = _package.allTypes.where((t) => t is PodEnum);
    print(path);
    return library(path.last)
      ..classes.addAll(podObjects.map(_makeClass));
  }

  Class _makeClass(PodObject po) {
    return class_(po.id)
      ..members.addAll(po.fields.map(_makeClassMember));
  }

  Member _makeClassMember(PodField field) {
    return member(field.id);
  }

  // end <class PodDartMapper>

  PodPackage _package;
}

// custom <library pod_dart>
// end <library pod_dart>
