library redstone_service;

import 'package:redstone/server.dart' as app;
import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/plugin.dart';

class User {
  
  @Field()
  String username;
  
  @Field()
  String password;
}

@app.Route("/service", methods: const [app.POST])
@Encode()
service(@Decode() User user) {
  var resp = [];
  for(var i = 0; i < 3; i++) {
    resp.add(user);
  }
  return resp;
}

@app.Route("/service_list", methods: const [app.POST])
@Encode()
serviceList(@Decode() List<User> users) {
  return users;
}