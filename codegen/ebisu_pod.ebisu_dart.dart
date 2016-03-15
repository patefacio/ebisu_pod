#!/usr/bin/env dart
import 'dart:io';
import 'package:args/args.dart';
import 'package:ebisu/ebisu.dart';
import 'package:ebisu/ebisu_dart_meta.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
// custom <additional imports>
// end <additional imports>
final _logger = new Logger('ebisuPodEbisuDart');

main(List<String> args) {
  Logger.root.onRecord.listen((LogRecord r) =>
      print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
  useDartFormatter = true;
  String here = absolute(Platform.script.toFilePath());
  // custom <ebisuPodEbisuDart main>

  Logger.root.level = Level.OFF;

  final purpose = '''
A general purpose *recursive design pattern* for modeling plain old
data components. Think *IDL*, or *json schema* but only covering the
basic data modeling of scalars, arrays, and dictionaries
(a.k.a. objects).

The goal is a simple modeling API that can then be used as inputs to
code generators.
''';

  final podFundamentals = [
    'char',
    'double',
    'object_id',
    'boolean',
    'date',
    'null',
    'regex',
    'int8',
    'int16',
    'int32',
    'int64',
    'uint8',
    'uint16',
    'uint32',
    'uint64',
    'date_time',
    'timestamp'
  ];

  String _topDir = dirname(dirname(here));
  useDartFormatter = true;
  System ebisu = system('ebisu_pod')
    ..includesHop = true
    ..license = 'boost'
    ..pubSpec.homepage = 'https://github.com/patefacio/ebisu_pod'
    ..pubSpec.version = '0.0.9'
    ..pubSpec.doc = purpose
    ..rootPath = _topDir
    ..doc = purpose
    ..testLibraries = [
      library('test_pod'),
      library('test_package'),
      library('test_example'),
      library('test_pod_cpp_mapper'),
      library('test_properties'),
    ]
    ..libraries = [
      library('ebisu_pod')
        ..includesLogger = true
        ..imports = [
          'mirrors',
          'package:ebisu/ebisu.dart',
          'package:id/id.dart',
        ]
        ..enums = [
          enum_('property_type')
            ..values = [
              enumValue('udt_property')
                ..doc =
                    'Property for annotating UDTs ([PodEnum] and [PodObject])',
              enumValue('field_property')
                ..doc = 'Property for annotating [PodField]',
              enumValue('package_property')
                ..doc = 'Property for annotating [PodPackage]',
            ]
            ..requiresClass = true
            ..isSnakeString = true
            ..hasLibraryScopedValues = true
        ]
        ..classes = [
          class_('property_error')
          ..doc = 'Indicates an attempt to access an invalid property'
          ..defaultCtorStyle = requiredParms
          ..isImmutable = true
          ..members = [
            member('property_type')..type = 'PropertyType',
            member('item_accessed'),
            member('property'),
          ],
          class_('property_definition')
            ..doc =
                'Identity of a property that can be associated with a [PodType], [PodField] or [PodPackage]'
            ..defaultMemberAccess = RO
            ..hasOpEquals = true
            ..members = [
              member('id')
                ..doc = 'Id associated with property'
                ..access = RO
                ..type = 'Id',
              member('property_type')
                ..doc =
                    'What this [PropertyDefinition] is associated with: [PodType], [PodField] or [PodPackage]'
                ..type = 'PropertyType',

              member('doc')
                ..doc =
                    'Documentation for the [PropertyDefinition]/[Property].',

              member('default_value')
                ..doc =
                    'The default value for a [Property] associated with *this* [PropertyDefinition]'
                ..type = 'dynamic',

              member('is_value_valid_predicate')
                ..doc =
                    'Predicate to determine of [Property] identified by [PropertyDefinition] is valid'
                ..type = 'PropertyValueValidPredicate',
            ],
          class_('property')
            ..doc =
                'A property associated with a [PodType], [PodField] or [PodPackage]'
            ..hasOpEquals = true
            ..members = [
              member('property_definition')
                ..doc = 'Reference [PropertyDefinition] for this property'
                ..access = RO
                ..type = 'PropertyDefinition',
              member('value')
                ..doc = 'Value of the property'
                ..access = RO
                ..type = 'dynamic',
            ],
          class_('property_set')
            ..doc =
                'A set of properties associated with a [PodTy[e], [PodField] or [PodPackage]'
            ..members = [
              member('properties')
                ..type = 'Map<String /* Property Name */, Property>'
                ..access = IA
                ..classInit = {},
            ],
          class_('property_definition_set')
            ..doc =
                'A collection of properties that may be associated with elements in a [PodPackage]'
            ..defaultMemberAccess = RO
            ..members = [
              member('id')
                ..doc = '''
Indentifier for the set of properties.

For example, there might be a *capnpPropertyDefinitionSet* designed to
shape the PODS into something that can code generate *capnp* IDL. In
that case the fields might have a *numeric* property to correspond to
the conventinos required by *capnp*.
'''
                ..type = 'Id',
              member('field_property_definitions')
                ..doc = 'Set of [PropertyDefinition]s for fields'
                ..type = 'Set<PropertyDefinition>'
                ..access = RO
                ..classInit = 'new Set()',
              member('udt_property_definitions')
                ..doc =
                    'Set of [PropertyDefinition]s for udts [objects and enums]'
                ..type = 'Set<PropertyDefinition>'
                ..access = RO
                ..classInit = 'new Set()',
              member('package_property_definitions')
                ..doc = 'Set of [PropertyDefinition]s for packages'
                ..type = 'Set<PropertyDefinition>'
                ..access = RO
                ..classInit = 'new Set()',
            ],
          class_('pod_type')
            ..doc = 'Base class for all [PodType]s'
            ..isAbstract = true
            ..members = [
              member('id')
                ..type = 'Id'
                ..access = RO,
              member('doc')..doc = 'Documentation for fixed size string',
            ],
          class_('pod_user_defined_type')
            ..extend = 'PodType'
            ..doc = 'Base class for user defined types'
            ..isAbstract = true
            ..mixins = ['PropertySet']
            ..members = [],
          class_('pod_enum')
            ..doc = 'Represents an enumeration'
            ..extend = 'PodUserDefinedType'
            ..members = [
              member('values')
                ..type = 'List<String>'
                ..classInit = [],
            ],
          class_('fixed_size_type')
            ..doc =
                'Base class for [PodType]s that may have a fixed size specified'
            ..extend = 'PodType'
            ..isAbstract = true
            ..customCodeBlock.snippets.add('bool get isFixedSize => true;'),
          class_('variable_size_type')
            ..extend = 'PodType'
            ..isAbstract = true
            ..customCodeBlock
                .snippets
                .add('bool get isFixedSize => maxLength != null;')
            ..members = [
              member('max_length')
                ..doc = 'If non-0 indicates length capped to [max_length]'
                ..type = 'int'
                ..access = RO,
            ],
          class_('pod_constant')
            ..doc = 'Represents a constant'
            ..defaultCtorStyle = requiredParms
            ..members = [
              member('id')
                ..type = 'Id'
                ..access = RO,
              member('pod_type')
                ..doc = 'Type of the constant'
                ..type = 'PodType',
              member('value')
                ..doc = 'Value for the constant'
                ..type = 'dynamic',
            ],
          class_('str_type')
            ..doc = '''
Used to define string types, which may have a fixed type.

The primary purpose for modeling data as fixed size strings over the
more general string type is so code generators may optimize for speed
by allocating space for strings inline.
'''
            ..extend = 'VariableSizeType'
            ..members = [
              member('type_cache')
                ..doc = 'Cache of all fixed size strings'
                ..access = IA
                ..isStatic = true
                ..type = 'Map<int, StrType>'
                ..classInit = 'new Map<int, StrType>()',
            ],
          class_('binary_data_type')
            ..doc = 'Stores binary data as array of bytes'
            ..extend = 'VariableSizeType'
            ..members = [
              member('type_cache')
                ..doc = 'Cache of all fixed size BinaryData types'
                ..access = IA
                ..isStatic = true
                ..type = 'Map<int, BinaryDataType>'
                ..classInit = 'new Map<int, BinaryDataType>()',
            ],
          class_('pod_array_type')
            ..doc = 'A [PodType] that is an array of some [referencedType].'
            ..extend = 'VariableSizeType'
            ..members = [
              member('referred_type')
                ..doc = '''
Type associated with the field.

May be a PodType, PodTypeRef, or a String.
If it is a String it is converted to a PodTypeRef
'''
                ..type = 'dynamic'
                ..access = IA,
            ],
          class_('pod_type_ref')
            ..doc =
                'Combination of owning package name and name of a type within it'
            ..extend = 'PodType'
            ..hasUntypedOpEquals = true
            ..defaultMemberAccess = RO
            ..members = [
              member('package_name')..type = 'PackageName',
              member('resolved_type')..type = 'PodType',
            ],
          class_('pod_field')
            ..doc = 'A field, which is a named and type entry, in a [PodObject]'
            ..mixins = ['PropertySet']
            ..hasOpEquals = true
            ..members = [
              member('id')
                ..type = 'Id'
                ..access = RO,
              member('doc')..doc = 'Documentation for the field',
              member('is_index')
                ..doc = 'If true the field is defined as index'
                ..classInit = false,
              member('pod_type')
                ..doc = '''
Type associated with the field.

May be a PodType, PodTypeRef, or a String.
If it is a String it is converted to a PodTypeRef
'''
                ..type = 'dynamic'
                ..isInHashCode = false
                ..access = IA,
              member('default_value')..type = 'dynamic',
              member('property_set')
                ..doc = 'Any properties associated with this type'
                ..access = IA
                ..classInit = 'new PropertySet()',
            ],
          class_('pod_object')
            ..extend = 'PodUserDefinedType'
            ..members = [
              member('fields')
                ..type = 'List<PodField>'
                ..classInit = [],
            ],
          class_('package_name')
            ..doc = '''
Package names are effectively a list of Id isntances.

They can be constructed from and represented by the common dotted form:

   [ id('dossier'), id('common') ] => 'dossier.common'

   [ id('dossier'), id('balance_sheet') ] => 'dossier.balance_sheet'
'''
            ..hasOpEquals = true
            ..members = [
              member('path')
                ..type = 'List<Id>'
                ..classInit = []
                ..access = RO,
            ],
          class_('pod_package')
            ..doc =
                'Package structure to support organization of pod definitions'
            ..extend = 'Entity'
            ..mixins = ['PropertySet']
            ..defaultMemberAccess = RO
            ..members = [
              member('name')
                ..doc = 'Name of package'
                ..type = 'PackageName',
              member('imports')
                ..doc =
                    'Packages required by (ie containing referenced types) this package'
                ..type = 'List<PodPackage>'
                ..classInit = [],
              member('pod_constants')
                ..doc = 'Named constants within the package'
                ..type = 'List<PodConstant>'
                ..classInit = [],
              member('named_types')
                ..doc =
                    'The named and therefore referencable types within the package'
                ..type = 'List<PodType>'
                ..classInit = [],
              member('all_types')
                ..doc =
                    'All types within the package including *anonymous* types'
                ..type = 'Set'
                ..access = IA,
              member('property_definition_sets')
                ..doc = 'Any properties associated with this type'
                ..access = RO
                ..type = 'List<PropertyDefinitionSet>'
                ..classInit = [],
            ],
        ]
        ..classes.addAll(podFundamentals.map((var t) => class_('${t}_type')
          ..extend = 'FixedSizeType'
          ..withClass((Class cls) {
            cls.withCustomBlock((cb) {
              cb
                ..tag = null // No need for custom block
                ..snippets.add(
                    '''
${cls.id.capCamel}._() : super(new Id('${makeId(t).snake}')) {}

toString() => id.capCamel;

''');
            });
          })))
        ..withCustomBlock(
            (cb) => cb.snippets.add(brCompact(podFundamentals.map((f) {
                  final clsId = makeId(f);
                  final clsName = clsId.capCamel;
                  return "final $clsName = new ${clsName}Type._();";
                })))),
      library('pod_cpp')
        ..doc = 'Consistent mapping of *plain old data* to C++ structs'
        ..imports = [
          'package:ebisu/ebisu.dart',
          'package:ebisu_pod/ebisu_pod.dart',
          'package:ebisu_cpp/ebisu_cpp.dart',
          'package:id/id.dart',
          'package:quiver/iterables.dart',
        ]
        ..classes = [
          class_('pod_cpp_mapper')
            ..doc = 'Given a pod package, maps the data definitions to C++'
            ..defaultMemberAccess = RO
            ..members = [
              member('package')
                ..doc = 'Package to generate basic C++ mappings for'
                ..type = 'PodPackage'
                ..ctors = [''],
              member('namespace')
                ..doc = 'Napespace into which to place the type hierarchy'
                ..type = 'Namespace',
              member('header')
                ..doc = 'C++ header with all PodObject and PodEnum definitions'
                ..type = 'Header'
                ..access = IA,
            ],
        ]
    ];

  ebisu.generate();

  _logger.warning('''
**** NON GENERATED FILES ****
${indentBlock(brCompact(nonGeneratedFiles))}
''');

  // end <ebisuPodEbisuDart main>
}

// custom <ebisuPodEbisuDart global>
// end <ebisuPodEbisuDart global>
