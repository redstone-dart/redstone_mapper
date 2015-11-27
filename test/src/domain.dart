library domain_test;

import 'package:collection/equality.dart';
import 'package:redstone_mapper/mapper.dart';

final dateTest = DateTime.parse("2014-08-11 12:23:00");

class GenericProperty {
  @Field()
  String value;
}

class SpecializedProperty extends GenericProperty {
  @Field()
  String value;
}

class TestObj {
  @Field()
  String value1;

  @Field(view: "value2")
  int value2;

  @Field()
  bool value3;

  @Field()
  DateTime value4;

  @Field()
  GenericProperty property;

  bool operator ==(other) {
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
    property: $property
  ''';
}

class TestComplexObj extends TestObj {
  @Field()
  TestInnerObj innerObj;

  @Field()
  List<TestInnerObj> innerObjs;

  @Field()
  SpecializedProperty property;

  @Field()
  Map<int, TestInnerObj> mapInnerObjs;

  operator ==(other) {
    return other is TestComplexObj &&
        super == (other) &&
        other.innerObj == innerObj &&
        const ListEquality().equals(other.innerObjs, innerObjs) &&
        const MapEquality().equals(other.mapInnerObjs, mapInnerObjs);
  }

  int get hashCode => toString().hashCode;

  String toString() => '''
    ${super.toString()}
    innerObj: $innerObj
    innerObjs: $innerObjs
    mapInnerObjs: $mapInnerObjs
    property: $property
  ''';
}

class TestInnerObj {
  String _innerObjValue;

  @Field()
  String get innerObjValue => _innerObjValue;

  @Field()
  set innerObjValue(String value) => _innerObjValue = value;

  bool operator ==(other) {
    return other is TestInnerObj && other.innerObjValue == innerObjValue;
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

class User {
  @Field()
  String username;

  @Field()
  String password;
}

TestObj createSimpleObj() {
  var p = new GenericProperty()..value = "genericProperty";
  var obj = new TestObj()
    ..value1 = "str"
    ..value2 = 10
    ..value3 = true
    ..value4 = dateTest
    ..property = p;
  return obj;
}

TestComplexObj createComplexObj() {
  var p = new SpecializedProperty()..value = "specializedProperty";
  var innerObj1 = new TestInnerObj()..innerObjValue = "obj1";
  var innerObj2 = new TestInnerObj()..innerObjValue = "obj2";
  var innerObj3 = new TestInnerObj()..innerObjValue = "obj3";
  var obj = new TestComplexObj()
    ..value1 = "str"
    ..value2 = 10
    ..value3 = true
    ..value4 = dateTest
    ..innerObj = innerObj1
    ..innerObjs = [innerObj2, innerObj3]
    ..mapInnerObjs = {1: innerObj1, 2: innerObj2, 3: innerObj3}
    ..property = p;
  return obj;
}
