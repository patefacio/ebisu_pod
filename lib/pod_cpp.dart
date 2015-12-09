/// Consistent mapping of *plain old data* to C++ structs
library ebisu_pod.pod_cpp;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu/ebisu_cpp.dart';
import 'package:id/id.dart';

// custom <additional imports>
// end <additional imports>

/// Given a pod package, maps the data definitions to C++
class PodCppMapper {
  PodCppMapper(this.package);

  /// Package to generate basic C++ mappings for
  Package package;

  /// Napespace into which to place the type hierarchy
  Napespace namespace;

  // custom <class PodCppMapper>

  // end <class PodCppMapper>

}

// custom <library pod_cpp>
// end <library pod_cpp>
