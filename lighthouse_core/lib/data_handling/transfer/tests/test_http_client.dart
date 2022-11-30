import '../../data_handling.dart';

void main(List<String> args) async {
  // GET
  final Response r = await DB.get(GetObjectById('Projects', 'abracadabra'));
  print(r.payload);
  print(r.jwtToken);
  /* Expected output
  {}
  null
   */

  // GET JWT
  final Response r2 =
      await DB.getJwtToken(GetJwtToken('john.bappleseed@gmail.com', 'john69'));
  print(r2.payload);
  print(r2.jwtToken);
  /*
  {_id: 2c256ed6-4b32-444e-bd06-c7dafa90938f, _owner: a088b700-0e08-4ce1-961a-89a9b442f2a4, _createdDate: 2022-11-29T02:33:54.450Z, _updatedDate: 2022-11-29T02:34:00.822Z, objectId: abracadabra}
  authed
  */

  DB.deinit();
}
