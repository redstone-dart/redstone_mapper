@TestOn('vm')
library server_test;

import 'dart:convert' as conv;

import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';
import 'package:test/test.dart';

import 'package:redstone/redstone.dart';
import 'package:redstone_mapper/plugin.dart';
import '../src/redstone_service.dart';
import '../src/common_tests.dart';
import '../src/domain.dart';

main() {
  bootstrapMapper();

  installCommonTests();

  test("Redstone Plugin", () async {
    addPlugin(getMapperPlugin());
    await redstoneSetUp([#redstone_service]);

    var user = new User()
      ..username = "user"
      ..password = "1234";
    var req = new MockRequest("/service",
        method: POST, bodyType: JSON, body: encode(user));
    var req2 = new MockRequest("/service_list",
        method: POST, bodyType: JSON, body: encode([user, user, user]));

    var expected = conv.JSON.encode([
      {"username": "user", "password": "1234"},
      {"username": "user", "password": "1234"},
      {"username": "user", "password": "1234"}
    ]);

    var resp = await dispatch(req);

    expect(resp.mockContent, equals(expected));

    resp = await dispatch(req2);

    expect(resp.mockContent, equals(expected));

    redstoneTearDown();
  });
}
