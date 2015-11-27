@TestOn("browser")
library client_test;

import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';
import 'package:test/test.dart';

import 'src/common_tests.dart';

main() {
  bootstrapMapper();

  installCommonTests();
}
