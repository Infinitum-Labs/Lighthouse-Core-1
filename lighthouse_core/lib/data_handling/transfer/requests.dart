part of core.data_handling.transfer;

abstract class GetRequest extends Request {
  GetRequest(super.path);
}

abstract class PostRequest extends Request {
  PostRequest(super.path, super.payload);
}

abstract class PatchRequest extends Request {
  PatchRequest(super.path, super.payload);
}

abstract class PutRequest extends Request {
  PutRequest(super.path, super.payload);
}

abstract class DeleteRequest extends Request {
  DeleteRequest(super.path);
}

class GetObjectById extends GetRequest {
  final String objectId;
  final String collectionId;

  GetObjectById(this.collectionId, this.objectId) : super('/getById') {
    params.addEntries([
      MapEntry("objectId", objectId),
      MapEntry("collectionId", collectionId),
    ]);
  }
}

class GetJwtToken extends GetRequest {
  final String emailAddress;
  final String password;

  GetJwtToken(this.emailAddress, this.password) : super('/getJwtToken') {
    params.addEntries([
      MapEntry("emailAddress", emailAddress),
      MapEntry("password", password),
    ]);
  }
}

class BulkGetByFilter extends GetRequest {
  final String collectionId;
  final Query queryObject;

  BulkGetByFilter(this.collectionId, this.queryObject)
      : super('/bulkGetByFilter') {
    params.addEntries([
      MapEntry("collectionId", collectionId),
      MapEntry("queryObject", json.encode(queryObject.filters)),
    ]);
  }
}

class Create extends PostRequest {
  final String collectionId;

  Create(this.collectionId, dynamic payload) : super('/create', payload) {
    params.addEntries([
      MapEntry("collectionId", collectionId),
    ]);
  }
}

class BulkCreate extends PostRequest {
  final String collectionId;

  BulkCreate(this.collectionId, dynamic payload)
      : super('/bulkCreate', payload) {
    params.addEntries([
      MapEntry("collectionId", collectionId),
    ]);
  }
}

class UpdateById extends PatchRequest {
  final String collectionId;
  final String objectId;

  UpdateById(this.collectionId, this.objectId, payload)
      : super('/updateById', payload) {
    params.addEntries([
      MapEntry("collectionId", collectionId),
      MapEntry("objectId", objectId),
    ]);
  }
}

class DeleteById extends DeleteRequest {
  final String collectionId;
  final String objectId;

  DeleteById(this.collectionId, this.objectId) : super('/deleteById') {
    params.addEntries([
      MapEntry("collectionId", collectionId),
      MapEntry("objectId", objectId),
    ]);
  }
}
