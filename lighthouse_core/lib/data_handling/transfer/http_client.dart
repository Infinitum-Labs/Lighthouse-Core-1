part of core.data_handling.transfer;

typedef JSON = Map<String, dynamic>;

class JWTToken {
  final String value;
  JWTToken(this.value);
  @override
  String toString() => value;
}

class Request {
  JWTToken? jwtToken;
  final JSON params = {};
  final String path;
  final dynamic payload;

  Request(this.path, [this.payload]);

  JSON get json => {
        'headers': {
          'Authorization': jwtToken.toString(),
        },
        'body': {
          'params': params,
          if (payload != null) 'payload': payload,
        },
      };

  void injectJwt(JWTToken jwtToken) => this.jwtToken = jwtToken;
}

class Response {
  late JWTToken jwtToken;
  late int statusCode;
  late dynamic statusMsg;
  late JSON payload;

  Response({
    required this.jwtToken,
    required this.statusCode,
    required this.statusMsg,
    required this.payload,
  });

  Response.fromJSON(JSON json, String jwtString) {
    jwtToken = JWTToken(jwtString);
    statusCode = json['status']['code'];
    statusMsg = json['status']['msg'];
    payload = json['payload'];
  }

  JSON get json => {
        'headers': {
          'Authorization': jwtToken.toString(),
        },
        'body': {
          'status': {
            'code': statusCode,
            'msg': statusMsg,
          },
          'payload': payload,
        }
      };
}

class DB {
  static const String authority = "infinitumlabsinc.editorx.io";

  static const String api = "/lighthousecloud/_functions";

  static JWTToken _jwtToken = JWTToken('xxxxxxx');

  static final HttpClient _client = HttpClient();

  static void deinit() => _client.close();

  static Future<Response> getJwtToken(GetJwtToken req) async {
    final HttpClientRequest httpReq =
        await _client.getUrl(Uri.https(authority, api + req.path, req.params));
    final HttpClientResponse httpRes = await httpReq.close();
    final JSON res = json.decode(await httpRes.transform(utf8.decoder).join());
    final Response response =  Response.fromJSON(
        res, httpRes.headers.value(HttpHeaders.authorizationHeader)!);

    return response;
  }

  static Future<Response> get(GetRequest req) async {
    req.injectJwt(_jwtToken);
    final HttpClientRequest httpReq =
        await _client.getUrl(Uri.https(authority, api + req.path, req.params));
    final HttpClientResponse httpRes = await httpReq.close();
    final JSON res = json.decode(await httpRes.transform(utf8.decoder).join());
    return Response.fromJSON(
        res, httpRes.headers.value(HttpHeaders.authorizationHeader)!);
  }
}
