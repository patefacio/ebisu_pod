library ebisu_pod.pod;

import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('pod');

enum PodType {
  podDouble,
  podString,
  podObject,
  podArray,
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

/// Convenient access to PodType.podDouble with *podDouble* see [PodType].
///
const PodType podDouble = PodType.podDouble;

/// Convenient access to PodType.podString with *podString* see [PodType].
///
const PodType podString = PodType.podString;

/// Convenient access to PodType.podObject with *podObject* see [PodType].
///
const PodType podObject = PodType.podObject;

/// Convenient access to PodType.podArray with *podArray* see [PodType].
///
const PodType podArray = PodType.podArray;

/// Convenient access to PodType.podBinaryData with *podBinaryData* see [PodType].
///
const PodType podBinaryData = PodType.podBinaryData;

/// Convenient access to PodType.podObjectId with *podObjectId* see [PodType].
///
const PodType podObjectId = PodType.podObjectId;

/// Convenient access to PodType.podBoolean with *podBoolean* see [PodType].
///
const PodType podBoolean = PodType.podBoolean;

/// Convenient access to PodType.podDate with *podDate* see [PodType].
///
const PodType podDate = PodType.podDate;

/// Convenient access to PodType.podNull with *podNull* see [PodType].
///
const PodType podNull = PodType.podNull;

/// Convenient access to PodType.podRegex with *podRegex* see [PodType].
///
const PodType podRegex = PodType.podRegex;

/// Convenient access to PodType.podInt32 with *podInt32* see [PodType].
///
const PodType podInt32 = PodType.podInt32;

/// Convenient access to PodType.podInt64 with *podInt64* see [PodType].
///
const PodType podInt64 = PodType.podInt64;

/// Convenient access to PodType.podTimestamp with *podTimestamp* see [PodType].
///
const PodType podTimestamp = PodType.podTimestamp;

class PodType {
  PodType podType;

  // custom <class PodType>

  PodType(this.podType);

  get isScalar => this is PodScalar;
  get isArray => this is PodArray;
  get isObject => this is PodObject;

  // end <class PodType>

}

class PodScalar extends PodType {
  // custom <class PodScalar>

  PodScalar(PodType podType) : super(podType);
  toString() => 'PodScalar($podType)';

  // end <class PodScalar>

}

class PodArray extends PodType {
  PodType referredType;

  // custom <class PodArray>

  PodArray(this.referredType) : super(PodType.podArray);
  toString() => 'PodArray($podType<${referredType.id}>)';

  // end <class PodArray>

}

class PodField {
  Id get id => _id;

  /// If true the field is defined as index
  bool isIndex = false;
  PodType podType;
  dynamic defaultValue;

  // custom <class PodField>

  bool isIndex = false;
  PodType podType;
  dynamic defaultValue;

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

  PodObject(this._id, [this.podFields]) : super(PodType.podObject);

  toString() =>
      brCompact(['PodObject($id)', indentBlock(brCompact(podFields))]);

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
  } else if (podType is PodType) {
    return new PodField(id, new PodScalar(podType));
  }
}

PodObject podObject(id, [podFields]) => new PodObject(makeId(id), podFields);

PodArray podArray(dynamic referredType) => referredType is PodType
    ? new PodArray(referredType)
    : referredType is PodType
        ? new PodArray(new PodScalar(referredType))
        : throw 'podArray(...) requires PodType or PodType: $referredType';

PodField podArrayField(id, referredType) =>
    podField(id, podArray(referredType));

// end <library pod>
