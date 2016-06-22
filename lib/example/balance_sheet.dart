library ebisu_pod.example.balance_sheet;

import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:logging/logging.dart';

// custom <additional imports>
// end <additional imports>

final _logger = new Logger('balance_sheet');

// custom <library balance_sheet>

final balanceSheet = new PodPackage('bs.balance_sheet', namedTypes: [
  enum_('holding_type', ['other', 'stock', 'bond', 'cash', 'blend',])
    ..doc = '''
Is the holding stock (equity), bond, cash, some blend of those or other.''',
  enum_('account_type', [
    'other',
    'roth_irs401k',
    'traditional_irs401k',
    'college_irs529',
    'traditional_ira',
    'investment',
    'brokerage',
    'checking',
    'health_savings_account',
    'savings',
    'money_market',
    'mattress',
  ])..doc = 'Type of account',
  object('date_value', [field('date', Date), field('value', Double)]),
  object('holding', [
    field('holding_type', 'holding_type')..doc = 'Type of the holding',
    field('quantity', 'date_value')..doc = 'Quantity as of the date',
    field('unit_value', 'date_value')..doc = 'Unit value as of the date',
    field('cost_basis', Double),
  ])
    ..doc = '''
The holding for a given symbol (or a sythetic aggregate as in an account other_holdings).

Both quantity and unitValue have dates associated with them. The marketValue of
the holding is based on the latest date of the two. This date can be different
(most likely older) than the date associated with the BalanceSheet owning the
holding.''',
  object('portfolio_account')
    ..doc =
        'The map of holdings indexed by symbol (or similar name unique to the portfolio).'
    ..fields.addAll([
      field('account_type', 'account_type')
        ..doc = 'Type of the portfolio account',
      field('descr')..doc = 'Description of the account',
      field('stout', Boolean)..doc = 'Is it a beefy account',
      field('num_symbols', Int32)..doc = 'Number of symbols in account',
    ])
]);

final dossier = new PodPackage('dossier', imports: [
  balanceSheet,
], namedTypes: [
  object('dossier', [
    field('portfolio_account', array('bs.balance_sheet.portfolio_account')),
  ])]);


// end <library balance_sheet>

main([List<String> args]) {
// custom <main>

  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.INFO;

  //  print(balanceSheet.details);

  print(dossier.details);

// end <main>
}
