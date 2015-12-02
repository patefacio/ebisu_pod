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
      ]
      ..classes = [

        class_('pod_type')
        ..members = [
        ],

        class_('pod_enum')
        ..extend = 'PodType'
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('values')..type = 'List<String>'..classInit = [],
          member('doc')..doc = 'Documentation for the enum',
        ],

        class_('pod_scalar')
        ..extend = 'PodType'
        ..members = [
          member('value')..isFinal = true..type = 'int',
        ],

        class_('pod_fixed_size_string')
        ..doc = '''
Used to store strings that have a capped size.

The primary purpose for modeling data as fixed size string over the
more general scalar string type is so code generators may optimize for
speed by allocating space for strings inline.
'''
        ..extend = 'PodType'
        ..members = [
          member('doc')..doc = 'Documentation for fixed size string',
          member('max_length')
          ..doc = 'If non-0 indicates length capped to [max_length]'
          ..classInit = 0,
          member('type_cache')
          ..doc = 'Cache of all fixed size strings'
          ..access = IA
          ..isStatic = true
          ..type = 'Map<int, PodFixedSizeString>'
          ..classInit = 'new Map<int, PodFixedSizeString>()',
        ],

        class_('pod_array')
        ..extend = 'PodType'
        ..hasOpEquals = true
        ..members = [
          member('referred_type')..type = 'PodType',
          member('doc')..doc = 'Documentation for the array',
          member('max_length')
          ..doc = 'If non-0 indicates length capped to [max_length]'
          ..classInit = 0,
        ],

        class_('pod_field')
        ..hasOpEquals = true
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('is_index')
          ..doc = 'If true the field is defined as index'
          ..classInit = false,
          member('pod_type')..type = 'PodType',
          member('default_value')..type = 'dynamic',
          member('doc')..doc = 'Documentation for the field',
        ],

        class_('pod_object')
        ..extend = 'PodType'
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('pod_fields')..type = 'List<PodField>'..classInit = [],
          member('doc')..doc = 'Documentation for the object',
        ],
      ],
    ];


  ebisu.generate();

  _logger.warning('''
**** NON GENERATED FILES ****
${indentBlock(brCompact(nonGeneratedFiles))}
''');
}
