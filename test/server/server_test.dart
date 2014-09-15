library server_test;

import 'dart:convert';

import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';
import 'package:unittest/unittest.dart';

import 'package:redstone/server.dart' as app;
import 'package:redstone/mocks.dart';
import 'package:redstone_mapper/plugin.dart';
import '../src/redstone_service.dart';
import '../src/common_tests.dart';
import '../src/domain.dart';

main() {
  
  bootstrapMapper();

  installCommonTests();

  test("Redstone Plugin", () {
    
    app.addPlugin(getMapperPlugin());
    app.setUp([#redstone_service]);
    
    var user = new User()
                    ..username = "user"
                    ..password = "1234";
    var req = new MockRequest("/service", method: app.POST, 
        bodyType: app.JSON, body: encode(user));
    var req2 = new MockRequest("/service_list", method: app.POST, 
        bodyType: app.JSON, body: encode([user, user, user]));
    
    var expected = JSON.encode([
      {"username": "user", "password": "1234"},
      {"username": "user", "password": "1234"},
      {"username": "user", "password": "1234"}
    ]);
    
    return app.dispatch(req).then((resp) {
      expect(resp.mockContent, equals(expected));
      
    }).then((_) => app.dispatch(req2)).then((resp) {
      expect(resp.mockContent, equals(expected));
      
      app.tearDown();
    });
    
  });
}