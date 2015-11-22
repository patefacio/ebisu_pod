import "dart:io";
import "package:path/path.dart" as path;
import "package:ebisu/ebisu.dart";
import "package:ebisu/ebisu_dart_meta.dart";
import "package:logging/logging.dart";

String _topDir;

final _logger = new Logger('ebisu_pod');

void main() {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  String here = path.absolute(Platform.script.toFilePath());

  Logger.root.level = Level.OFF;

  final purpose = '''
A general purpose *recursive design pattern* for modeling plain old
data components. Think *IDL*, or *json schema* but only covering the
basic data modeling of scalars, arrays, and dictionaries
(a.k.a. objects).

The goal is a simple modeling API that can then be used as inputs to
code generators.
''';

  _topDir = path.dirname(path.dirname(here));
  useDartFormatter = true;
  System ebisu = system('ebisu_pod')
    ..includesHop = true
    ..license = 'boost'
    ..pubSpec.homepage = 'https://github.com/patefacio/ebisu_pod'
    ..pubSpec.version = '0.0.1'
    ..pubSpec.doc = purpose
    ..rootPath = _topDir
    ..doc = purpose
    ..testLibraries = [
      library('test_pod'),
    ]
    ..libraries = [

      library('pod')
      ..includesLogger = true
      ..imports = [
        'package:ebisu/ebisu.dart',
        'package:id/id.dart',
      ]
      ..enums = [
        enum_('pod_type')
        ..hasLibraryScopedValues = true
        ..values = [
          'pod_double',
          'pod_string',
          'pod_object',
          'pod_array',
          'pod_binary_data',
          'pod_object_id',
          'pod_boolean',
          'pod_date',
          'pod_null',
          'pod_regex',
          'pod_int32',
          'pod_int64',
          'pod_timestamp',
        ]
      ]
      ..classes = [

        class_('pod_type')
        ..members = [
          member('pod_type')..type = 'PodType',
        ],

        class_('pod_scalar')
        ..extend = 'PodType'
        ..members = [
        ],

        class_('pod_array')
        ..extend = 'PodType'
        ..members = [
          member('referred_type')..type = 'PodType',
        ],

        class_('pod_field')
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('is_index')
          ..doc = 'If true the field is defined as index'
          ..classInit = false,
          member('pod_type')..type = 'PodType',
          member('default_value')..type = 'dynamic',
        ],

        class_('pod_object')
        ..extend = 'PodType'
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('pod_fields')..type = 'List<PodField>'..classInit = [],
        ],
      ],
    ];


  ebisu.generate();

  _logger.warning('''
**** NON GENERATED FILES ****
${indentBlock(brCompact(nonGeneratedFiles))}
''');
}
