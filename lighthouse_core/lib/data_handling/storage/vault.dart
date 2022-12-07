part of core.data_handling.storage;

class Vault {
  static final Map<String, LighthouseObject> index = {};
  static final List<String> dirtyObjects = [];
  static final List<String> deletions = [];
  static final List<String> creations = [];

  static Future<void> createAll(List<LighthouseObject> objects) async {
    for (int i = 0; i < objects.length; i++) {
      final LighthouseObject obj = objects[i];
      index.addAll({obj.objectId: obj});
      creations.add(obj.objectId);
    }
  }

  static Future<List<LighthouseObject>> readAll(
      List<ObjectId> objectIds) async {
    final List<LighthouseObject> objects = [];
    for (int i = 0; i < objects.length; i++) {
      final LighthouseObject? obj = index[i];
      if (obj != null) objects.add(obj);
    }
    return objects;
  }

  static Future<void> updateAll(List<LighthouseObject> objects) async {
    for (int i = 0; i < objects.length; i++) {
      final LighthouseObject obj = objects[i];
      index[obj.objectId]?.revisions.push(objects[i].revisions.peek);
      if (!dirtyObjects.contains(obj.objectId)) {
        dirtyObjects.add(obj.objectId);
      }
    }
  }

  static Future<void> deleteAll(List<LighthouseObject> objects) async {
    for (int i = 0; i < objects.length; i++) {
      deletions.add(objects[i].objectId);
    }
  }
}

class Storage {
  static final Table usersTable = UsersTable();

  static void init(List<LighthouseObject> objects) {
    usersTable.insertRecords(objects.whereType<User>());
  }

  static Future<List<LighthouseObject>> readAll(
      List<ObjectId> objectIds) async {
    final TableQuery tableQuery = TableQuery()
      ..addFilter(
        'objectId',
        Filter<String>((String s) => objectIds.contains(s)),
      );
    return usersTable.getAll(await usersTable.query(tableQuery));
  }
}
