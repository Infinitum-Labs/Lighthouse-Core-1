part of core.data_handling.storage;

abstract class Table {
  final TableField<String> objectId = TableField('objectId');
  late List<TableField> fields = [objectId];

  Future<List<LighthouseObject>> getAll(List<int> indexes) async {
    final List<LighthouseObject> objects = [];
    LoopUtils.iterateOver<int>(indexes, (int index) async {
      objects.add(await createLighthouseObject(index));
    });
    return objects;
  }

  Future<LighthouseObject> createLighthouseObject(int index);

  void insertRecords(Iterable<LighthouseObject> objects) {}

  Future<LighthouseObject> update<T>(
      ObjectId objId, TableField<T> tableField, T value) async {
    final int index = await queryObjectId(objId);
    tableField.cells[index] = value;
    return createLighthouseObject(index);
  }

  /// Returns the index of a record, queried using a unique property
  Future<int> queryObjectId(ObjectId objId) async =>
      objectId.cells.indexWhere((String s) => s == objId);

  /// Returns the indexes of the records which match the query
  Future<List<int>> query(TableQuery tableQuery) async {
    final Iterable<String> filteredProperties = tableQuery.parameters.keys;
    List<int> hitIndexes = [];
    final Iterable<TableField<dynamic>> targetedFields =
        fields.where((e) => filteredProperties.contains(e.propertyName));
    for (int i = 0; i < targetedFields.length; i++) {
      final TableField<dynamic> thisField = targetedFields.elementAt(i);
      final List<int> hits = thisField.queryCells(
          tableQuery.parameters[thisField.propertyName]!, hitIndexes);
      if (hits.isEmpty) {
        return [];
      } else {
        hitIndexes.clear();
        hitIndexes.addAll(hits);
      }
    }
    return hitIndexes;
  }
}

class UsersTable extends Table {
  final TableField<String> userName = TableField('userName');
  final TableField<String> emailAddress = TableField('emailAddress');
  final TableField<String> password = TableField('password');
  final TableField<String> workbenchId = TableField('workbenchId');
  final TableField<List<Permission>> permissions = TableField('permissions');
  final TableField<FixedStack<ObjectRevision>> revisions =
      TableField('revisions');

  UsersTable() {
    fields.addAll([
      userName,
      emailAddress,
      password,
      workbenchId,
      permissions,
      revisions
    ]);
  }

  @override
  Future<LighthouseObject> createLighthouseObject(int index) async {
    return User(
      objectId: objectId.cellAt(index),
      revisions: revisions.cellAt(index),
      userName: userName.cellAt(index),
      emailAddress: emailAddress.cellAt(index),
      password: password.cellAt(index),
      workbenchId: workbenchId.cellAt(index),
      permissions: permissions.cellAt(index),
    );
  }
}

class TableField<T> {
  final String propertyName;
  final List<T> cells = [];

  TableField(this.propertyName);

  T cellAt(int index) => cells[index];

  List<int> queryCells(
    List<Filter<T>> filters, [
    List<int> hitIndexes = const [],
  ]) {
    final List<int> hits = [];
    final int filtersLength = filters.length;
    if (hitIndexes.isEmpty) {
      final int cellsLength = cells.length;
      for (int i = 0; i < cellsLength; i++) {
        bool hit = true;
        for (int j = 0; j < filtersLength; j++) {
          if (filters[j].checkerFn(cells[i]) == false) {
            hit = false;
            break;
          }
        }
        if (hit) hits.add(i);
      }
    } else {
      final List<T> selectedCells = [];
      LoopUtils.iterateOver<int>(hitIndexes, (int index) {
        selectedCells.add(cells[index]);
      });
      final int selectedCellsLength = selectedCells.length;
      for (int i = 0; i < selectedCellsLength; i++) {
        bool hit = true;
        for (int j = 0; j < filtersLength; j++) {
          if (filters[j].checkerFn(cells[i]) == false) {
            hit = false;
            break;
          }
        }
        if (hit) hits.add(i);
      }
    }
    return hits;
  }
}

class TableQuery {
  final Map<String, List<Filter>> parameters = {};

  void addFilter(String property, Filter filter) {
    if (parameters.containsKey(property)) {
      parameters[property]!.add(filter);
    } else {
      parameters[property] = [filter];
    }
  }
}

class Filter<T> {
  final Type dataType = T;
  final bool Function(T) checkerFn;

  Filter(this.checkerFn);

  static Filter numBetween(num start, num end) {
    return Filter<num>((num value) => start < value && value < end);
  }

  static Filter stringContains(String substring) {
    return Filter<String>((String value) => value.contains(substring));
  }
}
