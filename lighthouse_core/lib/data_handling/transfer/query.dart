part of core.data_handling.transfer;

class Query {
  final List<JSON> filters = [];

  void between(String prop, dynamic rangeStart, dynamic rangeEnd) {
    filters.add({
      'type': 'between',
      'prop': prop,
      'rangeStart': rangeStart,
      'rangeEnd': rangeEnd,
    });
  }

  void contains(String prop, String substring) {
    filters.add({
      'type': 'contains',
      'prop': prop,
      'substring': substring,
    });
  }

  void equals(String prop, dynamic value) {
    filters.add({
      'type': 'eq',
      'prop': prop,
      'value': value,
    });
  }

  void notEquals(String prop, dynamic value) {
    filters.add({
      'type': 'ne',
      'prop': prop,
      'value': value,
    });
  }

  void greaterThan(String prop, dynamic value) {
    filters.add({
      'type': 'gt',
      'prop': prop,
      'value': value,
    });
  }

  void greaterThanEqual(String prop, dynamic value) {
    filters.add({
      'type': 'ge',
      'prop': prop,
      'value': value,
    });
  }

  void lessThan(String prop, dynamic value) {
    filters.add({
      'type': 'lt',
      'prop': prop,
      'value': value,
    });
  }

  void lessThanEqual(String prop, dynamic value) {
    filters.add({
      'type': 'le',
      'prop': prop,
      'value': value,
    });
  }

  void hasSome(String prop, List values) {
    filters.add({
      'type': 'hasSome',
      'prop': prop,
      'values': values,
    });
  }
}
