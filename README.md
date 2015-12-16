# Ebisu Pod

  *Pre-Alpha*

[![Build Status](https://drone.io/github.com/patefacio/ebisu_pod/status.png)](https://drone.io/github.com/patefacio/ebisu_pod/latest)

Dart modeling for *Plain Old Data*

# Purpose

A general purpose *recursive design pattern* for modeling plain old
data components. Think *IDL*, or *json schema* but only covering the
basic data modeling of scalars, arrays, and dictionaries
(a.k.a. objects).

The goal is a simple modeling API that can then be used as inputs to
code generators.

## A Simple Modeling Library

If you have experience with any *interface definition languages* or
IDLs (*CORBA*, *Apache Thrift*, *Google Protocol Buffers*, etd), this
should feel familar. Since these *ebisu* projects are about code
generation, rather than commit to an existing IDL, which usually
entails its own code generation solution, the approach taken here is
the typical *extra level of indirection*. We pull some of the common
IDL features into the library and then support modeling with
declarative instantiations of that *meta-data*. The process of
creating a *PodPackage* is analagous to creating an instance of an
IDL. The benefit of this approach include:

- *Competitive Selection*: Decisions on serialization solutions can
  informed by having multiple approaches tried against the same data
  set.

- *Additivie*: Single source for multiple needs. For example, generate
  mongo bson serialization for mongo as well as msgpack serialization
  for network communication.

- *Programatic Control*: Because the meta-language is implemented with
  a library programatic creation of models from structured data sets
  is simplified.

## Types

All types support the [PodType] interface.

## User Defined Data Types

User's may defined two types of data type:

```
| Type      | Description                      |
|-----------+----------------------------------|
| PodEnum   | An enumerated type               |
| PodObject | An object type with named fields |
```

These types are created with an [Id] instance identifying the type.

```
| Built-In Type | Literal Name |
|---------------+--------------|
| DoubleType    | Double       |
| Int32Type     | Int32        |
| Int64Type     | Int64        |
| DateType      | Date         |
| RegexType     | Regex        |
| TimestampType | Timestamp    |
| StrType       | Str          |
```

For these built-in types, there is an actual Dart type
(e.g. Int32Type) and a single instance of that type (e.g. Int32) that
may be used in declarations.

### A Few Functions

Because the modeling language is a Dart library and not a *DSL*, the
creation of new types and fields is acheived with functions.

 - *object(id, [fields])*: Create a named object with a list of fields
 - *field(id, [podType])*: Create a named field within an object
 - *array(referredType)*: Create an array of *referredType*
 - *package(packageName, imports, namedTypes)*: Create a package of types

```dart
object('point', [
  field('x', Int32),
  field('y', Int32)
])
```

This defines a *POD* object called *point* with two fields, *x* of
type *Int32* and *y* of type *Int32*.

### Reference To Other Types

The [PodArrayType] requires a reference to the type of elements in the
array. Since the [PodArrayType] models a reference to a single type it
is necessarily a *homogeneous* collection. To enable the same type to
be referenced in multiple other types without redefining it, it is
convenient to be able to able to reference other types by
name. Therefore, the *podType* argument to the *field* function may be
either an actual *PodType* (e.g. *Int32* or some user defined type) or
it may be a literal string that references another type.

### Scale With Packages

As projects grow it can be useful to not require all object types to
be within the same file. The typical approach to supporting this
requirement is to allow the grouping of types into packages and allow
fields and arrays to refer to other types, both within their package
and without.

#### Package Name Convention

Packages are named with the familar dotted-name notation. 

Type references use the same notation. 

```dart

package('sports.baseball', 
  namedTypes: [
    object('player_stats', [
      field('unforced_errors', Int32),
      field('batting_average', Double),
    ]),
    object('player_stat', [
      field('player'),
      field('player_stats', 'player_stats')
    ]),
    object('player_stats_map', [
      field('pairs', 'player_stat')
    ]),
  ])
```

### Variable Size Types

These types may have a variable number of elements:

  - *Str(N)*: characters for [StrType]
  - *BinaryData(N)*: bytes for [BinaryDataType]
  - *PodArray(N)*: instances of some *referencedType*, which is a
    [PodType] 

For modeling purposes, these types support specification of
*maxLength* which may enable optimizations on the serialization end.

### Support For Recursive Models

```dart
object('person', [
  field('name'),                      // If no type is specified, default is [Str]
  field('children', array('person'))  // Types may be referenced by name (ie literal string)
])

```



# Examples

[Balance Sheet](lib/example/balance_sheet)

The following declarative *ebisu_pod* dart code models a few simple types from a balance sheet.

```dart
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
    ..fields = [
      field('account_type', 'account_type')
        ..doc = 'Type of the portfolio account',
      field('descr')..doc = 'Description of the account',
      field('stout', Boolean)..doc = 'Is it a beefy account',
    ]
]);
```

And here is the generated C++ for *msgpack* [See ebisu_msgpack](https://github.com/patefacio/ebisu_msgpack):

```C++

#ifndef __BS_BALANCE_SHEET_BALANCE_SHEET_HPP__
#define __BS_BALANCE_SHEET_BALANCE_SHEET_HPP__

#include "ebisu/utils/block_indenter.hpp"
#include "msgpack.hpp"
#include <boost/date_time/gregorian/gregorian.hpp>
#include <iosfwd>
#include <string>

namespace bs {
namespace balance_sheet {
enum class Holding_type {
  Other_e,
  Stock_e,
  Bond_e,
  Cash_e,
  Blend_e
};

inline char const* to_c_str(Holding_type e) {
  switch(e) {
    case Holding_type::Other_e: return "Other_e";
    case Holding_type::Stock_e: return "Stock_e";
    case Holding_type::Bond_e: return "Bond_e";
    case Holding_type::Cash_e: return "Cash_e";
    case Holding_type::Blend_e: return "Blend_e";
    default: {
      return "Invalid Holding_type";
    }
  }
}

inline std::ostream& operator<<(std::ostream &out, Holding_type e) {
  return out << to_c_str(e);
}

enum class Account_type {
  Other_e,
  Roth_irs401k_e,
  Traditional_irs401k_e,
  College_irs529_e,
  Traditional_ira_e,
  Investment_e,
  Brokerage_e,
  Checking_e,
  Health_savings_account_e,
  Savings_e,
  Money_market_e,
  Mattress_e
};

inline char const* to_c_str(Account_type e) {
  switch(e) {
    case Account_type::Other_e: return "Other_e";
    case Account_type::Roth_irs401k_e: return "Roth_irs401k_e";
    case Account_type::Traditional_irs401k_e: return "Traditional_irs401k_e";
    case Account_type::College_irs529_e: return "College_irs529_e";
    case Account_type::Traditional_ira_e: return "Traditional_ira_e";
    case Account_type::Investment_e: return "Investment_e";
    case Account_type::Brokerage_e: return "Brokerage_e";
    case Account_type::Checking_e: return "Checking_e";
    case Account_type::Health_savings_account_e: return "Health_savings_account_e";
    case Account_type::Savings_e: return "Savings_e";
    case Account_type::Money_market_e: return "Money_market_e";
    case Account_type::Mattress_e: return "Mattress_e";
    default: {
      return "Invalid Account_type";
    }
  }
}

inline std::ostream& operator<<(std::ostream &out, Account_type e) {
  return out << to_c_str(e);
}

struct Date_value
{

  Date_value() = default;

  Date_value(
    boost::gregorian::date date,
    double value) :   date (date),
    value (value) {
  }

  friend inline
  std::ostream& operator<<(std::ostream &out,
                           Date_value const& item) {
    out << "Date_value(" << &item << ") {";
    out << "\n  date:" << item.date;
    out << "\n  value:" << item.value;
    out << "\n}\n";
    return out;
  }

  MSGPACK_DEFINE(date, value);

  boost::gregorian::date date {};
  double value {};

};

struct Holding
{

  Holding() = default;

  Holding(
    Holding_type holding_type,
    Date_value quantity,
    Date_value unit_value,
    double cost_basis) :   holding_type (holding_type),
    quantity (quantity),
    unit_value (unit_value),
    cost_basis (cost_basis) {
  }

  friend inline
  std::ostream& operator<<(std::ostream &out,
                           Holding const& item) {
    out << "Holding(" << &item << ") {";
    out << "\n  holding_type:" << item.holding_type;
    out << "\n  quantity:" << item.quantity;
    out << "\n  unit_value:" << item.unit_value;
    out << "\n  cost_basis:" << item.cost_basis;
    out << "\n}\n";
    return out;
  }

  MSGPACK_DEFINE(holding_type, quantity, unit_value, cost_basis);

  Holding_type holding_type {};
  Date_value quantity {};
  Date_value unit_value {};
  double cost_basis {};

};

struct Portfolio_account
{

  Portfolio_account() = default;

  Portfolio_account(
    Account_type account_type,
    std::string const & descr,
    bool stout) :   account_type (account_type),
    descr (descr),
    stout (stout) {
  }

  friend inline
  std::ostream& operator<<(std::ostream &out,
                           Portfolio_account const& item) {
    out << "Portfolio_account(" << &item << ") {";
    out << "\n  account_type:" << item.account_type;
    out << "\n  descr:" << item.descr;
    out << "\n  stout:" << item.stout;
    out << "\n}\n";
    return out;
  }

  MSGPACK_DEFINE(account_type, descr, stout);

  Account_type account_type {};
  std::string descr {};
  bool stout {};

};


} // namespace balance_sheet
} // namespace bs

MSGPACK_ADD_ENUM(bs::balance_sheet::Holding_type);
MSGPACK_ADD_ENUM(bs::balance_sheet::Account_type);
template< typename T >
inline msgpack::sbuffer to_msgpack(T const& t) {
  msgpack::sbuffer sbuf;
  msgpack::pack(sbuf, t);
  return sbuf;
}

template < typename T >
inline void from_msgpack(msgpack::sbuffer &sbuf, T &t) {
  msgpack::unpacked msg;
  msgpack::unpack(msg, sbuf.data(), sbuf.size());
  msgpack::object obj = msg.get();
  obj.convert(&t);
}
#ifndef __BOOST_DATE_MSGPACK_SERIALIZER__
#define __BOOST_DATE_MSGPACK_SERIALIZER__
namespace msgpack {
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS) {
namespace adaptor {

template<>
struct convert<boost::gregorian::date> {
    msgpack::object const& operator()(msgpack::object const& o, boost::gregorian::date& v) const {
        v = boost::gregorian::from_undelimited_string(o.as<std::string>());
        return o;
    }
};

template<>
struct pack<boost::gregorian::date> {
    template <typename Stream>
    packer<Stream>& operator()(msgpack::packer<Stream>& o, boost::gregorian::date const& v) const {
        o.pack(boost::gregorian::to_iso_string(v));
        return o;
    }
};

} // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack
#endif // __BOOST_DATE_MSGPACK_SERIALIZER__


#endif // __BS_BALANCE_SHEET_BALANCE_SHEET_HPP__

```

