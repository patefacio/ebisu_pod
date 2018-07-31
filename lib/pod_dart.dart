/// Consistent mapping of pod to dart classes
library ebisu_pod.pod_dart;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu/ebisu_dart_meta.dart' as ebisu show EnumValue;
import 'package:ebisu/ebisu_dart_meta.dart' hide EnumValue;
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

// custom <additional imports>
// end <additional imports>

final Logger _logger = new Logger('pod_dart');

/// Given pod package maps definitions to dart classes/libraries
class PodDartMapper {
  PodDartMapper(this._package);

  /// Package to generate dart code for
  PodPackage get package => _package;
  Map get classToObjectMap => _classToObjectMap;
  Map get memberToFieldMap => _memberToFieldMap;

  // custom <class PodDartMapper>

  List<Library> createLibraries() => [_createLibrary(package)];

  List<Library> createCoverageTestLibraries() =>
      [_createCoverageTestLibrary(package)];

  static String _objectTest(PodObject po) {
    final name = po.id.capCamel;
    return brCompact([
      '''
test('$name default ctor', () {
final obj1 = new $name();
final obj2 = new $name();
final obj3 = obj1.copy();

expect(identical(obj1, obj2), false);
expect(identical(obj2, obj3), false);
expect(identical(obj1, obj3), false);
expect(obj1, obj2);
expect(obj1.hashCode, obj2.hashCode);
expect(obj2, obj3);
expect(obj2.hashCode, obj3.hashCode);
expect($name.fromJson(obj1.toJson()), obj1);
expect($name.fromJson(JSON.encode(obj1.toJson())), obj1);
expect($name.fromJson(null), null);
expect(obj1.toString() is String, true);
});
'''
    ]);
  }

  static String _enumTest(PodEnum pe) {
    final name = pe.id.capCamel;
    return brCompact([
      """
test('$name values', () =>
  expect($name.values.every((v) => v.compareTo(v) == 0), true));

test('$name values other', () =>
  expect($name.values.every((v) =>
    $name.values.every((v2) => identical(v,v2) ||
      (v2.compareTo(v) != 0 && v.compareTo(v2) != 0))), true));

test('$name to/from json', () =>
  expect($name.values.every((v) => $name.fromJson(v.toJson()) == v), true));

test('$name to/from string', () =>
  expect($name.values.every((v) => $name.fromString(v.toString()) == v), true));

test('$name hashCode', () =>
  expect($name.values.every((v) => v.hashCode == v.value), true));

""",
    ]);
  }

  Library _createCoverageTestLibrary(PodPackage package) {
    final path = package.packageName.path;
    final relPath = package.getProperty('relativePath');
    final libName = '${package.packageName.path.last.snake}.dart';
    return library_('test_coverage_${path.last.snake}')
      ..imports.add(join(relPath ?? '../lib', libName))
      ..imports.add('dart:convert')
      ..withMainCustomBlock((CodeBlock cb) {
        final enums = package.localNamedTypes.where((nt) => nt is PodEnum);
        cb.snippets.add(brCompact([
          enums.isNotEmpty
              ? '''
group('enum coverage', () {
${brCompact(enums.map(_enumTest))}
});
'''
              : null
        ]));

        final objects = package.localNamedTypes.where((nt) => nt is PodObject);
        cb.snippets.add(brCompact([
          objects.isNotEmpty
              ? '''
group('object coverage', () {
${brCompact(objects.map(_objectTest))}
});
'''
              : null
        ]));
      })
      ..isTest = true;
  }

  Library _createLibrary(PodPackage package) {
    final path = package.packageName.path;
    final result = library_(path.last)
      ..classes.addAll(package.localPodObjects.map(_makeClass))
      ..enums.addAll(package.localPodEnums.map(_makeEnum))
      ..importAndExportAll(package.getProperty('importAndExportAll') ?? [])
      ..imports.addAll(package.getProperty('imports') ?? [])
      ..importAndExportAll(package.imports.map((PodPackage pkg) {
        final relPath = pkg.getProperty('relativePath');
        final importPath = relPath == null ? '' : '$relPath/';
        return '$importPath${pkg.packageName.path.last.snake}.dart';
      }));
    return result;
  }

  Class _makeClass(PodObject po) {
    final result = class_(po.id)
      ..doc = po.doc
      ..hasJsonSupport = true // TODO: drive from properties
      ..hasJsonToString = true // TODO: drive from properties
      ..hasOpEquals = true // TODO: drive from properties
      ..jsonKeyFormat = JsonKeyFormat.snake
      ..isCopyable = true // TODO: drive from properties
      ..withCtor(
          '',
          (Ctor ctor) => ctor
            ..isConst = false
            ..tag = po.getProperty('defaultCtorTag'))
      ..members.addAll(po.fields.map(_makeClassMember));
    classToObjectMap[result] = po;

    if (po.getProperty('hasFieldUpdateMethod') ?? false) {
      addFieldUpdateMethod(po, result);
    }

    return result;
  }

  addFieldUpdateMethod(PodObject po, Class cls) {
    final paths = po.fieldPaths;

    pathKey(FieldPath fieldPath) => doubleQuote(fieldPath.pathKey);

    pathResolved(FieldPath fieldPath) {
      int i = 0;
      return doubleQuote(fieldPath.path
          .map((f) => f?.id?.camel ?? '\${placeHolders[${i++}]}')
          .join('.'));
    }

    pathUpdateFunction(FieldPath fieldPath) {
      final placeHolderCount = fieldPath.numPlaceHolders;
      return '''
///
(List<String> placeHolders) {
  assert(placeHolders.length == $placeHolderCount);
  return ${pathResolved(fieldPath)};
}

''';
    }

    pathEntry(FieldPath fieldPath) {
      return combine(
          ['///\n', pathKey(fieldPath), ':', pathUpdateFunction(fieldPath)]);
    }

    pathMapContents() => br(paths.map(pathEntry), ',\n\n');

    cls.customCodeBlock.snippets.add('''
static final Map _fieldUpdateMethods = {
${indentBlock(pathMapContents())}
};
void updateField(String fieldSpec, List<String> placeHolders) {

}
''');
  }

  _initMember(PodField field) => field.podType is PodMapType
      ? {}
      : field.podType is PodArrayType
          ? []
          : field.podType is PodObject ||
                  field.podType is DateType ||
                  field.podType is UuidType ||
                  field.podType is PodPredefinedType
              ? 'new ${field.podType.id.capCamel}()'
              : field.podType is PodEnum
                  ? '${field.podType.id.capCamel}.${field.podType.values.first.id.shout}'
                  : null;

  Member _makeClassMember(PodField field) {
    _logger.info('PodField ${field.id} type is ${field.podType.runtimeType}'
        ' => ${_initMember(field)}');
    final result = member(field.id)
      ..ctorInit = field.getProperty('ctorInit') ?? _initMember(field)
      ..isFinal = field.getProperty('isFinal') ?? false
      ..isInComparable = field.getProperty('isInComparable') ?? true
      ..isInEquality = field.getProperty('isInEquality') ?? true
      ..isInHashCode = field.getProperty('isInHashCode') ?? true
      ..type = getType(field.podType)
      ..doc = field.doc;

    memberToFieldMap[result] = field;
    return result;
  }

  Enum _makeEnum(PodEnum e) {
    return new Enum(e.id)
      ..doc = e.doc
      ..hasJsonSupport = true // TODO: drive from properties
      ..values = e.values
          .map((ev) => new ebisu.EnumValue(ev.id, null)..doc = ev.doc)
          .toList();
  }

  // end <class PodDartMapper>

  PodPackage _package;
  Map _classToObjectMap = {};
  Map _memberToFieldMap = {};
}

// custom <library pod_dart>

getType(PodType t) {
  if (t is PodArrayType) return 'List<${getType(t.referredType)}>';
  if (t is PodMapType)
    return 'Map<${getType(t.keyReferredType)}, ${getType(t.valueReferredType)}>';
  else if (t is PodObject || t is PodEnum)
    return t.id.capCamel;
  else if (t is BooleanType)
    return 'bool';
  else if (t is DateType)
    return 'Date';
  else if (t is DoubleType)
    return 'double';
  else if (t is UuidType)
    return 'Uuid';
  else if (t is PodPredefinedType) {
    final aliased = t.getProperty('dart_aliased_to');
    return aliased != null ? aliased : t.id.capCamel;
  } else if (t is Int8Type ||
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

// end <library pod_dart>
