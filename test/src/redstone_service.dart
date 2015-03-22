library redstone_service;

import 'package:redstone/redstone.dart';
import 'package:redstone_mapper/plugin.dart';

import 'domain.dart';

@Route("/service", methods: const [POST])
@Encode()
service(@Decode() User user) {
  var resp = [];
  for(var i = 0; i < 3; i++) {
    resp.add(user);
  }
  return resp;
}

@Route("/service_list", methods: const [POST])
@Encode()
serviceList(@Decode() List<User> users) {
  return users;
}