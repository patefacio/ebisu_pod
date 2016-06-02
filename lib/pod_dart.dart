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
        package.imports.fold([], (prev, pkg) => prev..add(_createLibrary(pkg)));
    result.add(_createLibrary(package));
    return result;
  }

  Library _createLibrary(PodPackage package) {
    final path = package.packageName.path;
    final podObjects = _package.allTypes.where((t) => t is PodObject);
    final podEnums = _package.allTypes.where((t) => t is PodEnum);
    return library(path.last)
      ..classes.addAll(podObjects.map(_makeClass))
      ..enums.addAll(podEnums.map(_makeEnum));
  }

  Class _makeClass(PodObject po) {
    return class_(po.id)
      ..doc = po.doc
      ..members.addAll(po.fields.map(_makeClassMember));
  }

  Member _makeClassMember(PodField field) {
    print('Making field ${field.podType}');
    return member(field.id)
      ..type = _getType(field.podType)
      ..doc = field.doc;
  }

  Enum _makeEnum(PodEnum e) {
    return new Enum(e.id)
      ..doc = e.doc
      ..values = e.values;
  }

  _getType(PodType t) {
    if (t is PodArrayType)
      return 'List';
    else if (t is PodObject || t is PodEnum)
      return t.id.capCamel;
    else if (t is DateType)
      return 'Date';
    else if (t is DoubleType)
      return 'double';
    else if (t is Int8Type ||
        t is Int16Type ||
        t is Int32Type ||
        t is Int64Type ||
        t is Uint8Type ||
        t is Uint16Type ||
        t is Uint32Type ||
        t is Uint64Type)
      return 'int';
    else
      return 'String';
  }

  // end <class PodDartMapper>

  PodPackage _package;
}

// custom <library pod_dart>
// end <library pod_dart>
