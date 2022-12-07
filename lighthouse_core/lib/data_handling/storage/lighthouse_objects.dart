part of core.data_handling.storage;

abstract class LighthouseObject {
  final FixedStack<ObjectRevision> revisions;
  final ObjectId objectId;

  LighthouseObject({
    required this.objectId,
    required this.revisions,
  });

  LighthouseObject.fromJSON(JSON json)
      : revisions = FixedStack<ObjectRevision>()
          ..addAll((json['revisions'] as List<JSON>)
              .map((JSON json) => ObjectRevision.fromJSON(json))
              .toList()),
        objectId = json['objectId'] as String;

  void bump() => revisions..push(ObjectRevision.fromJSON(toJSON()));

  JSON toJSON();
}

class ObjectRevision {
  final JSON json;
  late int creationDate;

  ObjectRevision.fromJSON(JSON objJSON)
      : json = objJSON
          ..remove('objectId')
          ..remove('revisions')
          ..addAll(
              {'creationDate': DateTime.now().millisecondsSinceEpoch / 1000}) {
    creationDate = int.parse(json['creationDate'].toString());
  }
}

abstract class CoreObject extends LighthouseObject {
  CoreObject({
    required super.objectId,
    required super.revisions,
  });

  CoreObject.fromJSON(JSON json) : super.fromJSON(json);
}

class User extends CoreObject {
  final String userName;
  final String emailAddress;
  final String password;
  final String workbenchId;
  final List<Permission> permissions;

  User({
    required super.objectId,
    required super.revisions,
    required this.userName,
    required this.emailAddress,
    required this.password,
    required this.workbenchId,
    required this.permissions,
  });

  User.fromJSON(JSON json)
      : userName = json['userName'] as String,
        emailAddress = json['emailAddress'] as String,
        password = json['password'] as String,
        workbenchId = json['workbenchId'] as String,
        permissions = (json['permissions'] as List).listOf((e) => Permission()),
        super.fromJSON(json);

  @override
  JSON toJSON() {
    return {
      'userName': userName,
      // create codegen
    };
  }
}

/* class Workbench extends CoreObject {
  Workbench.fromJSON(JSON json) : super.fromJSON(json);

  List<String> get goals => json['goals'];
  set goals(List<String> goals) => json['goals'] = goals;

  List<String> get projects => json['projects'];
  set projects(List<String> projects) => json['projects'] = projects;

  List<String> get epics => json['epics'];
  set epics(List<String> epics) => json['epics'] = epics;

  List<String> get tasks => json['tasks'];
  set tasks(List<String> tasks) => json['tasks'] = tasks;

  List<String> get events => json['events'];
  set events(List<String> events) => json['events'] = events;

  List<String> get issues => json['issues'];
  set issues(List<String> issues) => json['issues'] = issues;

  List<String> get documents => json['documents'];
  set documents(List<String> documents) => json['documents'] = documents;

  List<String> get prototypes => json['prototypes'];
  set prototypes(List<String> prototypes) => json['prototypes'] = prototypes;

  List<String> get messages => json['messages'];
  set messages(List<String> messages) => json['messages'] = messages;
}
 */
abstract class SubObject extends LighthouseObject {
  SubObject.fromJSON(JSON json) : super.fromJSON(json);
}

class Anchor extends SubObject {
  Anchor.fromJSON(JSON json) : super.fromJSON(json);

  @override
  JSON toJSON() {
    // TODO: implement toJSON
    throw UnimplementedError();
  }
}

class ContextConstraint extends SubObject {
  ContextConstraint.fromJSON(JSON json) : super.fromJSON(json);
  @override
  JSON toJSON() {
    // TODO: implement toJSON
    throw UnimplementedError();
  }
}

class Schedule extends SubObject {
  Schedule.fromJSON(JSON json) : super.fromJSON(json);
  @override
  JSON toJSON() {
    // TODO: implement toJSON
    throw UnimplementedError();
  }
}

class Permission {}
