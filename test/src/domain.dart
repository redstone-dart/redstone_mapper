library domain_test;

import 'package:collection/equality.dart';
import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';

final dateTest = DateTime.parse("2014-08-11 12:23:00");

class TestObj {

  @Field()
  String value1;

  @Field(view: "value2")
  int value2;

  @Field()
  bool value3;

  @Field()
  DateTime value4;

  bool operator == (other) {
    return other is TestObj &&
    other.value1 == value1 &&
    other.value2 == value2 &&
    other.value3 == value3 &&
    other.value4 == value4;
  }

  int get hashCode => toString().hashCode;

  String toString() => '''
    value1: $value1
    value2: $value2
    value3: $value3
    value4: $value4
  ''';

}

class TestComplexObj extends TestObj {

  @Field()
  TestInnerObj innerObj;

  @Field()
  List<TestInnerObj> innerObjs;

  operator == (other) {
    return other is TestComplexObj &&
    super==(other) &&
    other.innerObj == innerObj &&
    const ListEquality().equals(other.innerObjs, innerObjs);
  }

  int get hashCode => toString().hashCode;

  String toString() => '''
    ${super.toString()}
    innerObj: $innerObj
    innerObjs: $innerObjs
  ''';
}

class TestInnerObj {

  String _innerObjValue;

  @Field()
  String get innerObjValue => _innerObjValue;

  @Field()
  set innerObjValue(String value) => _innerObjValue = value;

  bool operator == (other) {
    return other is TestInnerObj &&
    other.innerObjValue == innerObjValue;
  }

  int get hashCode => toString().hashCode;

  String toString() => '''
    innerObjValue: $innerObjValue
  ''';
}

class TestValidator extends Schema {

  @Field()
  @Matches(r"\w+")
  String value1;

  @Field()
  @Range(min: 9, max: 12)
  int value2;

  @Field()
  @NotEmpty()
  bool value3;

}

TestObj createSimpleObj() {
  var obj = new TestObj()
    ..value1 = "str"
    ..value2 = 10
    ..value3 = true
    ..value4 = dateTest;
  return obj;
}

TestComplexObj createComplexObj() {
  var innerObj1 = new TestInnerObj()..innerObjValue = "obj1";
  var innerObj2 = new TestInnerObj()..innerObjValue = "obj2";
  var innerObj3 = new TestInnerObj()..innerObjValue = "obj3";
  var obj = new TestComplexObj()
    ..value1 = "str"
    ..value2 = 10
    ..value3 = true
    ..value4 = dateTest
    ..innerObj = innerObj1
    ..innerObjs = [innerObj2, innerObj3];
  return obj;
}