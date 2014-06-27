library mapper_tests;

import 'dart:convert';

import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';
import 'package:unittest/unittest.dart';
import 'package:collection/equality.dart';

import 'package:redstone/server.dart' as app;
import 'package:redstone/mocks.dart';
import 'package:redstone_mapper/plugin.dart';
import 'redstone_service.dart';


class TestObj {
  
  @Field()
  String value1;
  
  @Field(view: "value2")
  int value2;
  
  @Field()
  bool value3;
  
  bool operator == (other) {
    return other is TestObj &&
            other.value1 == value1 &&
            other.value2 == value2 &&
            other.value3 == value3;
  }
  
  String toString() => '''
    value1: $value1
    value2: $value2
    value3: $value3
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
  
  String toString() => '''
    ${super.toString()}
    innerObj: $innerObj
    innerObjs: $innerObjs
  ''';
}

class TestInnerObj {
  
  @Field()
  String innerObjValue;
  
  bool operator == (other) {
    return other is TestInnerObj &&
        other.innerObjValue == innerObjValue;
  }
  
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
  
  @Field()
  String get test => "test";
  
  @Field()
  set test(String value) => null;
}

TestObj _createSimpleObj() {
  var obj = new TestObj()
          ..value1 = "str"
          ..value2 = 10
          ..value3 = true;
  return obj;
}

TestComplexObj _createComplexObj() {
  var innerObj1 = new TestInnerObj()..innerObjValue = "obj1";
  var innerObj2 = new TestInnerObj()..innerObjValue = "obj2";
  var innerObj3 = new TestInnerObj()..innerObjValue = "obj3";
  var obj = new TestComplexObj()
    ..value1 = "str"
    ..value2 = 10
    ..value3 = true
    ..innerObj = innerObj1
    ..innerObjs = [innerObj2, innerObj3];
  return obj;
}

main() {
  
  bootstrapMapper();
  
  group("Encode:", () {
    
    test("Simple object", () {
      
      var obj = _createSimpleObj();
      
      var data = encode(obj);
      
      expect(data, equals({
        "value1": "str",
        "value2": 10,
        "value3": true
      }));
      
    });
    
    test("Complex object", () {
      
      var obj = _createComplexObj();
      
      var data = encode(obj);
      
      expect(data, equals({
        "value1": "str",
        "value2": 10,
        "value3": true,
        "innerObj": {
          "innerObjValue": "obj1"
        },
        "innerObjs": [
          {"innerObjValue": "obj2"},
          {"innerObjValue": "obj3"}
        ]
      }));
    });
    
    test("List", () {
      
      var list = [_createSimpleObj(), _createSimpleObj()];
      
      var data = encode(list);
      var expected = {
        "value1": "str",
        "value2": 10,
        "value3": true
      };
      
      expect(data, equals([expected, expected]));
      
    });
    
  });
  
  group("Decode:", () {

    test("Simple object", () {
      
      var obj = _createSimpleObj();
      
      var data = {
        "value1": "str",
        "value2": 10,
        "value3": true
      };
      
      var decoded = decode(data, TestObj);
      
      expect(decoded, equals(obj));
    });
    
    test("Complex object", () {
      
      var obj = _createComplexObj();
      
      var data = {
        "value1": "str",
        "value2": 10,
        "value3": true,
        "innerObj": {
          "innerObjValue": "obj1"
        },
        "innerObjs": [
          {"innerObjValue": "obj2"},
          {"innerObjValue": "obj3"}
        ]
      };
      
      var decoded = decode(data, TestComplexObj);
      
      expect(decoded, equals(obj));
    });
    
    test("List", () {
      
      var data = {
        "value1": "str",
        "value2": 10,
        "value3": true,
        "innerObj": {
          "innerObjValue": "obj1"
        },
        "innerObjs": [
          {"innerObjValue": "obj2"},
          {"innerObjValue": "obj3"}
        ]
      };
      
      var list = [data, data];
      
      var decoded = decode(list, TestComplexObj);
      
      expect(decoded, equals([_createComplexObj(), _createComplexObj()]));
    });
  });

  group("Validator:", () {
    
    test("using validator object", () {
      var validator = new Validator(TestObj)
        ..add("value1", const Matches(r'\w+'))
        ..add("value2", const Range(min: 9, max: 12))
        ..add("value3", const NotEmpty());
      
      var testObj = _createSimpleObj();
      expect(validator.execute(testObj), isNull);
      
      testObj.value1 = ",*[";
      testObj.value2 = 2;
      testObj.value3 = null;
      
      var invalidFields = {
        "value1": ["matches"],
        "value2": ["range"],
        "value3": ["notEmpty"]
      };
      
      expect(validator.execute(testObj).invalidFields, equals(invalidFields));
    });
    
    test("using schema", () {
      var obj = new TestValidator()
                ..value1 = "str"
                ..value2 = 10
                ..value3 = true;
      
      expect(obj.validate(), isNull);
      
      obj.value1 = ",*[";
      obj.value2 = 2;
      obj.value3 = null;
      
      var invalidFields = {
        "value1": ["matches"],
        "value2": ["range"],
        "value3": ["notEmpty"]
      };
      
      expect(obj.validate().invalidFields, equals(invalidFields));
    });
    
  });
  
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