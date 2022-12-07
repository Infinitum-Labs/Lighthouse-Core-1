part of core.data_handling.transfer;

class Synchroniser {
  static late Timer timer;
  static void init() {
    timer = Timer.periodic(const Duration(seconds: 15), (_) => synchronise());
  }

  static Future<void> synchronise() async {
    final List<LighthouseObject> createdObjects =
        await Vault.readAll(Vault.creations);
    Vault.creations.clear();
    final List<ObjectId> deletions = Vault.deletions;
    Vault.deletions.clear();
    final List<ObjectId> dirtyObjects = Vault.dirtyObjects;
    Vault.dirtyObjects.clear();

    final Response response = await DB.update(
      SynchronisationUpdate(
        creations: createdObjects,
        deletions: deletions,
        dirtyObjects: dirtyObjects,
      ),
    );

    // response.dirtyObjectRevisions.forEach((revision) {
    //    Vault.replaceObject(handleMergeConflicts())
    // });
  }

  static Future<JSON> handleMergeConflicts(
      LighthouseObject clientCopy, ObjectRevision dbCopy) async {
    final bool clientCopyIsLatestRevision =
        clientCopy.revisions.peek.creationDate > dbCopy.creationDate;
    final JSON clientJSON = clientCopy.toJSON();
    final JSON dbJSON = dbCopy.json;
    LoopUtils.iterateOver<String>(dbJSON.keys.toList(), (String key) {
      if (clientJSON[key] != dbJSON[key]) {
        if (!clientCopyIsLatestRevision) clientJSON[key] = dbJSON[key];
      }
    });
    return clientJSON;
  }
}
