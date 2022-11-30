part of core.data_handling.transfer;

abstract class GetRequest extends Request {
  GetRequest(super.path);
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
