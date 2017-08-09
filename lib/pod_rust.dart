/// Consistent mapping of *plain old data* to rust structs
library ebisu_pod.pod_rust;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu_rs/ebisu_rs.dart';

// custom <additional imports>
// end <additional imports>

class PodRustMapper {
  PodRustMapper(this._package, this._module);

  /// Package to generate basic rust mappings for
  PodPackage get package => _package;

  /// Module to insert rust mappings
  Module get module => _module;

  // custom <class PodRustMapper>
  // end <class PodRustMapper>

  PodPackage _package;
  Module _module;
}

// custom <library pod_rust>
// end <library pod_rust>
