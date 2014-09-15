library client_test;

import 'dart:convert';

import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'src/common_tests.dart';

main() {
  useHtmlConfiguration();

  bootstrapMapper();

  installCommonTests();
}