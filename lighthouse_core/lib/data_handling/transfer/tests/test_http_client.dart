import 'dart:io';

import '../../data_handling.dart';
import 'package:markhor_testing_rig/markhor.dart';

void main() async {
  final Console httpServices = Console(
    IntegrationTest(
      "HTTP Services",
      unitTests: [
        UnitTest<Response>(
          'getJwtToken',
          asyncAction: (OutputPipe outputPipe) async {
            final Response r = await DB.getJwtToken(
                GetJwtToken('john.bappleseed@gmail.com', 'john69'));
            return (r);
          },
          reporters: (Response response) {
            return [
              ResultReporter('jwtToken', response.payload.first['signature'])
            ];
          },
        ),
        UnitTest<Response>(
          "getObjectById",
          asyncAction: (OutputPipe<Response> outputPipe) async {
            return (await DB.get(GetObjectById('Projects', 'abracadabra')));
          },
          reporters: (Response response) =>
              [ResultReporter('statusCode', response.statusCode)],
        ),
        UnitTest<Response>(
          'bulkGetByFilter',
          asyncAction: (OutputPipe outputPipe) async {
            return (await DB.get(
              BulkGetByFilter(
                'Projects',
                Query()
                  ..greaterThan('a', 10)
                  ..lessThan('a', 25),
              ),
            ));
          },
          reporters: (Response response) {
            return [
              ResultReporter('statusCode', response.statusCode),
              ResultReporter('payload', response.payload),
            ];
          },
        ),
        UnitTest<Response>(
          "create",
          asyncAction: (OutputPipe pipe) async {
            return (await DB.create(
              Create(
                'Users',
                {
                  "objectId": "us-g8t9o51w-hgppckzv",
                  "emailAddress": "bohn.jappleseed@gmail.com",
                  "password": "bohn69",
                  "userName": "Bohn Jappleseed",
                  "workbenchId": "wb-17nvrmjh-hgppckzv",
                  "permissions": ["read", "write"]
                },
              ),
            ));
          },
          reporters: (Response response) {
            return [ResultReporter('statusCode', response.statusCode)];
          },
        ),
        UnitTest<Response>(
          "bulkCreate",
          asyncAction: (OutputPipe pipe) async {
            return (await DB.create(
              BulkCreate(
                'Projects',
                [
                  {"objectId": "x", "a": 2},
                  {"objectId": "y", "a": 2},
                  {"objectId": "z", "a": 2}
                ],
              ),
            ));
          },
          reporters: (Response response) {
            return [ResultReporter('statusCode', response.statusCode)];
          },
        ),
        UnitTest<Response>(
          "updateById",
          asyncAction: (OutputPipe pipe) async {
            return (await DB.update(
              UpdateById(
                'Users',
                'us-g8t9o51w-hgppckzv',
                {"password": "bohnbap69"},
              ),
            ));
          },
          reporters: (Response response) {
            return [ResultReporter('statusCode', response.statusCode)];
          },
        ),
        UnitTest<Response>(
          "deleteById",
          asyncAction: (OutputPipe pipe) async {
            return (await DB
                .delete(DeleteById('Users', 'us-g8t9o51w-hgppckzv')));
          },
          reporters: (Response response) {
            return [ResultReporter('statusCode', response.statusCode)];
          },
        ),
        UnitTest<Response>(
          'X-getJwtToken-badCredentials',
          asyncAction: (OutputPipe outputPipe) async {
            final Response r = await DB.getJwtToken(
                GetJwtToken('john.bappleseed@gmail.com', 'johnbap69'));
            return (r);
          },
          reporters: (Response response) {
            return [ResultReporter('X-badCredentials', response.statusCode)];
          },
        ),
      ],
    ),
    ExecutionEnvironment(),
    TargetResult({
      'statusCode': (dynamic code) => 200 <= code && code < 300,
      'jwtToken': (dynamic token) => token != 'null',
      'payload': (dynamic payload) => payload != [],
      'X-badCredentials': (dynamic code) => code == 403,
    }),
  );

  final Console jwtArchitecture = Console(
    IntegrationTest('JWT Architecture', unitTests: [
      UnitTest<Response>(
        'getJwtToken',
        asyncAction: (OutputPipe outputPipe) async {
          final Response r = await DB
              .getJwtToken(GetJwtToken('john.bappleseed@gmail.com', 'john69'));
          return (r);
        },
        reporters: (Response response) {
          return [
            ResultReporter('jwtToken', response.payload.first['signature'])
          ];
        },
      ),
      UnitTest<Response>(
        "getObjectById",
        asyncAction: (OutputPipe<Response> outputPipe) async {
          final GetRequest r = GetObjectById('Projects', 'abracadabra');
          return (await DB.get(r));
        },
        reporters: (Response response) =>
            [ResultReporter('statusCode', response.statusCode)],
      ),
    ]),
    ExecutionEnvironment(),
    TargetResult({
      'statusCode': (dynamic code) => 200 <= code && code < 300,
      'jwtToken': (dynamic token) => token != 'null',
      'payload': (dynamic payload) => payload != [],
    }),
  );
  await httpServices.runProcess();
  exit(0);
}
