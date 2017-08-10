/// Consistent mapping of *plain old data* to rust structs
library ebisu_pod.pod_rust;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu_rs/ebisu_rs.dart' as ebisu_rs;
import 'package:ebisu_rs/ebisu_rs.dart' show Module;

// custom <additional imports>
// end <additional imports>

class PodRustMapper {
  PodRustMapper(this._package);

  /// Package to generate basic rust mappings for
  PodPackage get package => _package;

  // custom <class PodRustMapper>

  Module get module => _makeModule();

  Module _makeModule() {
    if (_module == null) {
      _module = new Module(this.package.id);

      final path = package.packageName.path;
      final podObjects = _package.allTypes.where((t) => t is PodObject);
      final podEnums = _package.allTypes.where((t) => t is PodEnum);

      podEnums.forEach((pe) {
        _module.enums.add(_makeEnum(pe));
      });

      podObjects.forEach((PodObject po) {
        _module.structs.add(_makeStruct(po));
      });
    }
    return _module;
  }

  _makeEnum(PodEnum pe) =>
      ebisu_rs.enum_(pe.id, pe.values.map((e) => e.id.snake))
      ..derive = [ ebisu_rs.Debug, ebisu_rs.Copy ];

  _makeStruct(PodObject po) => ebisu_rs.struct(po.id)
    ..derive = [ebisu_rs.Debug, ebisu_rs.Copy]
    ..fields
        .addAll(po.fields.map((PodField field) => ebisu_rs.field(field.id)));

  // end <class PodRustMapper>

  PodPackage _package;

  /// Module to insert rust mappings
  Module _module;
}

// custom <library pod_rust>
// end <library pod_rust>
