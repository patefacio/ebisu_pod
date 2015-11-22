library ebisu_pod.pod;

import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('pod');

enum PodScalarType {
  podDouble,
  podString,
  podBinaryData,
  podObjectId,
  podBoolean,
  podDate,
  podNull,
  podRegex,
  podInt32,
  podInt64,
  podTimestamp
}

/// Convenient access to PodScalarType.podDouble with *podDouble* see [PodScalarType].
///
const PodScalarType podDouble = PodScalarType.podDouble;

/// Convenient access to PodScalarType.podString with *podString* see [PodScalarType].
///
const PodScalarType podString = PodScalarType.podString;

/// Convenient access to PodScalarType.podBinaryData with *podBinaryData* see [PodScalarType].
///
const PodScalarType podBinaryData = PodScalarType.podBinaryData;

/// Convenient access to PodScalarType.podObjectId with *podObjectId* see [PodScalarType].
///
const PodScalarType podObjectId = PodScalarType.podObjectId;

/// Convenient access to PodScalarType.podBoolean with *podBoolean* see [PodScalarType].
///
const PodScalarType podBoolean = PodScalarType.podBoolean;

/// Convenient access to PodScalarType.podDate with *podDate* see [PodScalarType].
///
const PodScalarType podDate = PodScalarType.podDate;

/// Convenient access to PodScalarType.podNull with *podNull* see [PodScalarType].
///
const PodScalarType podNull = PodScalarType.podNull;

/// Convenient access to PodScalarType.podRegex with *podRegex* see [PodScalarType].
///
const PodScalarType podRegex = PodScalarType.podRegex;

/// Convenient access to PodScalarType.podInt32 with *podInt32* see [PodScalarType].
///
const PodScalarType podInt32 = PodScalarType.podInt32;

/// Convenient access to PodScalarType.podInt64 with *podInt64* see [PodScalarType].
///
const PodScalarType podInt64 = PodScalarType.podInt64;

/// Convenient access to PodScalarType.podTimestamp with *podTimestamp* see [PodScalarType].
///
const PodScalarType podTimestamp = PodScalarType.podTimestamp;

class PodType {
  // custom <class PodType>

  get isScalar => this is PodScalar;
  get isArray => this is PodArray;
  get isObject => this is PodObject;
  get typeName;

  // end <class PodType>

}

class PodScalar extends PodType {
  bool operator ==(PodScalar other) =>
      identical(this, other) || podScalarType == other.podScalarType;

  int get hashCode => podScalarType.hashCode;

  PodScalarType podScalarType;

  // custom <class PodScalar>

  PodScalar(this.podScalarType);
  toString() => 'PodScalar($podScalarType)';
  get typeName => toString();

  // end <class PodScalar>

}

class PodArray extends PodType {
  bool operator ==(PodArray other) =>
      identical(this, other) || referredType == other.referredType;

  int get hashCode => referredType.hashCode;

  PodType referredType;

  // custom <class PodArray>

  PodArray(this.referredType);
  toString() => 'PodArray(${referredType.typeName})';
  get typeName => toString();

  // end <class PodArray>

}

class PodField {
  bool operator ==(PodField other) => identical(this, other) ||
      _id == other._id &&
          isIndex == other.isIndex &&
          podType == other.podType &&
          defaultValue == other.defaultValue;

  int get hashCode => hash4(_id, isIndex, podType, defaultValue);

  Id get id => _id;

  /// If true the field is defined as index
  bool isIndex = false;
  PodType podType;
  dynamic defaultValue;

  // custom <class PodField>
  // custom <class PodField>

  PodField(this._id, [this.podType]);
  toString() => 'PodField($id:$podType)';

  // end <class PodField>

  Id _id;
}

class PodObject extends PodType {
  Id get id => _id;
  List<PodField> podFields = [];

  // custom <class PodObject>

  PodObject(this._id, [this.podFields]);

  get typeName => 'PodObject($_id)';

  toString() {
    print('to string on object $id');

    return brCompact([
      'PodObject($id)',
      indentBlock(
          brCompact(podFields.map((pf) => '${pf.id}:${pf.podType.typeName}')))
    ]);
  }

  bool get hasArray => podFields.any((pf) => pf.podType is PodArray);

  // end <class PodObject>

  Id _id;
}

// custom <library pod>

PodField podField(id, [podType]) {
  id = makeId(id);
  if (podType == null) {
    return new PodField(id);
  } else if (podType is PodType) {
    return new PodField(id, podType);
  } else if (podType is PodScalarType) {
    return new PodField(id, new PodScalar(podType));
  }
}

PodObject podObject(id, [podFields]) => new PodObject(makeId(id), podFields);

PodArray podArray(dynamic referredType) => referredType is PodType
    ? new PodArray(referredType)
    : referredType is PodScalarType
        ? new PodArray(new PodScalar(referredType))
        : throw 'podArray(...) requires PodType or PodScalarType: $referredType';

PodField podArrayField(id, referredType) =>
    podField(id, podArray(referredType));

// end <library pod>
