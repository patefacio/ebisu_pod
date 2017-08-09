library ebisu_pod.test_bitset;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu/ebisu.dart';

// end <additional imports>

final Logger _logger = new Logger('test_bitset');

// custom <library test_bitset>
// end <library test_bitset>

void main([List<String> args]) {
  if (args?.isEmpty ?? false) {
    Logger.root.onRecord.listen(
        (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
    Logger.root.level = Level.OFF;
  }
// custom <main>

  group('bitset', () {
    test('basics', () {
      var bs = bitSet('io_flags', 3);
      expect(bs.id, makeId('io_flags'));
      expect(bs.numBits, 3);
    });

    test('padding', () {
      var bs = bitSet('io_flags', 3, rhsPadBits: 2);
      expect(bs.id, makeId('io_flags'));
      expect(bs.numBits, 3);
      expect(bs.rhsPadBits, 2);
      expect(bs.lhsPadBits, 0);

      bs = bitSet('io_flags', 3, lhsPadBits: 2);
      expect(bs.id, makeId('io_flags'));
      expect(bs.numBits, 3);
      expect(bs.rhsPadBits, 0);
      expect(bs.lhsPadBits, 2);

      bs = bitSet('io_flags', 3, rhsPadBits: 2, lhsPadBits: 3)..doc = 'foo';
      expect(bs.id, makeId('io_flags'));
      expect(bs.numBits, 3);
      expect(bs.rhsPadBits, 2);
      expect(bs.lhsPadBits, 3);
    });
  });

// end <main>
}
