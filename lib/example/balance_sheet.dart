library ebisu_pod.example.balance_sheet;

import 'package:ebisu_pod/ebisu_pod.dart';

// custom <additional imports>
// end <additional imports>

// custom <library balance_sheet>

final holdingType =
    enum_('holding_type', ['other', 'stock', 'bond', 'cash', 'blend',])
      ..doc = '''
Is the holding stock (equity), bond, cash, some blend of those or other.''';

final dateValue =
    object('date_value', [field('date', Date), field('value', Double)]);

final holding = object('holding', [
  field('quantity', dateValue)..doc = 'Quantity as of the date',
  field('unit_value', dateValue)..doc = 'Unit value as of the date',
  field('cost_basis', Double)
])
  ..doc = '''
The holding for a given symbol (or a sythetic aggregate as in an account other_holdings).

Both quantity and unitValue have dates associated with them. The marketValue of
the holding is based on the latest date of the two. This date can be different
(most likely older) than the date associated with the BalanceSheet owning the
holding.''';

// end <library balance_sheet>

main([List<String> args]) {
// custom <main>

  print(holdingType);
  print(holding);

// end <main>
}
