part of core.data_handling.transfer;

class JWTToken {
  final String value;
  final int issuedAt;
  final int expiresAt;
  final String subject;
  final JSON raw;

  JWTToken(
    this.value, {
    required this.issuedAt,
    required this.expiresAt,
    required this.subject,
    required this.raw,
  });

  JSON get body => {
        'headers': raw['headers'],
        'payload': raw['payload'],
      };

  @override
  String toString() => "Bearer $value";
}

class Request {
  final JSON params = {};
  final String path;
  final dynamic payload;

  Request(this.path, [this.payload]);

  JSON get json => {
        'body': {
          'params': params,
          if (payload != null) 'payload': payload,
        },
      };

  void injectJwt(JWTToken jwtToken) {
    params.addAll({'jwt': jsonEncode(jwtToken.body)});
  }
}

class Response {
  late int statusCode;
  late dynamic statusMsg;
  late List<JSON> payload;

  Response({
    required this.statusCode,
    required this.statusMsg,
    required this.payload,
  });

  Response.fromJSON(JSON json) {
    statusCode = json['status']['code'];
    statusMsg = json['status']['msg'];
    payload = (json['payload'] as List).map((e) => e as JSON).toList();
  }

  JSON get json => {
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

  static late JWTToken _jwtToken;

  static final HttpClient _client = HttpClient();

  static void deinit() => _client.close();

  static Future<Response> getJwtToken(GetJwtToken req) async {
    final HttpClientRequest httpReq =
        await _client.getUrl(Uri.https(authority, api + req.path, req.params));
    final HttpClientResponse httpRes = await httpReq.close();
    final JSON res = json.decode(await httpRes.transform(utf8.decoder).join());
    if (res['status']['code'] == 200) {
      _jwtToken = JWTToken(
        res['payload'][0]['signature'],
        issuedAt: res['payload'][0]['payload']['iat'],
        expiresAt: res['payload'][0]['payload']['exp'],
        subject: res['payload'][0]['payload']['sub'],
        raw: res['payload'][0],
      );
    }
    final Response response = Response.fromJSON(res);
    return response;
  }

  static Future<Response> get(GetRequest req) async {
    req.injectJwt(_jwtToken);
    final HttpClientRequest httpReq =
        await _client.getUrl(Uri.https(authority, api + req.path, req.params));
    httpReq.headers.add(HttpHeaders.acceptHeader, 'application/json');
    httpReq.headers.add(HttpHeaders.authorizationHeader, _jwtToken.toString());
    final HttpClientResponse httpRes = await httpReq.close();
    final JSON res = json.decode(await httpRes.transform(utf8.decoder).join());
    return Response.fromJSON(
      res,
    );
  }

  static Future<Response> create(PostRequest req) async {
    req.injectJwt(_jwtToken);
    final HttpClientRequest httpReq =
        await _client.postUrl(Uri.https(authority, api + req.path, req.params));
    httpReq.headers.add(HttpHeaders.authorizationHeader, _jwtToken.toString());
    httpReq.add(utf8.encode(json.encode(req.payload)));
    final HttpClientResponse httpRes = await httpReq.close();
    final JSON res = json.decode(await httpRes.transform(utf8.decoder).join());
    return Response.fromJSON(res);
  }

  static Future<Response> update(PatchRequest req) async {
    req.injectJwt(_jwtToken);
    final HttpClientRequest httpReq =
        await _client.putUrl(Uri.https(authority, api + req.path, req.params));
    httpReq.headers.add(HttpHeaders.contentTypeHeader, 'application/json');
    httpReq.headers.add(HttpHeaders.acceptHeader, 'application/json');
    httpReq.headers.add(HttpHeaders.authorizationHeader, _jwtToken.toString());
    httpReq.add(utf8.encode(json.encode(req.payload)));
    final HttpClientResponse httpRes = await httpReq.close();
    final JSON res = json.decode(await httpRes.transform(utf8.decoder).join());
    return Response.fromJSON(res);
  }

  static Future<Response> replace(PutRequest req) async {
    throw UnimplementedError("PUT Requests not implemented yet");
  }

  static Future<Response> delete(DeleteRequest req) async {
    req.injectJwt(_jwtToken);
    final HttpClientRequest httpReq = await _client
        .deleteUrl(Uri.https(authority, api + req.path, req.params));
    httpReq.headers.add(HttpHeaders.authorizationHeader, _jwtToken.toString());
    final HttpClientResponse httpRes = await httpReq.close();
    final JSON res = json.decode(await httpRes.transform(utf8.decoder).join());
    return Response.fromJSON(res);
  }
}
