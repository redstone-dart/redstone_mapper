library redstone_mapper;

import 'dart:convert';
import 'dart:collection';

part 'package:redstone_mapper/src/mapper_impl.dart';
part 'package:redstone_mapper/src/validation_impl.dart';
part 'package:redstone_mapper/src/metadata.dart';

/**
 * Decode [data] to one or more objects of type [type], 
 * using [defaultCodec].
 * 
 * [data] is expected to be a Map or
 * a List, and [type] a class which contains members
 * annotated with the [Field] annotation. 
 * 
 * If [data] is a Map, then this function will return
 * an object of [type]. Otherwise, if [data] is a List, then a 
 * List<[type]> will be returned.
 * 
 * For more information on how the serialization 
 * and deserialization of objects works, see [Field].
 * 
 * When using on the client side, be sure to set the redstone_mapper's
 * transformer in your pubspec.yaml.
 */ 
dynamic decode(dynamic data, Type type) {
  return defaultCodec.decode(data, type);
}

/**
 * Encode [input] using [defaultCodec].
 * 
 * [input] can be an object or a List of objects.
 * If it's an object, then this function will return
 * a Map, otherwise a List<Map> will be returned.
 * 
 * For more information on how the serialization 
 * and deserialization of objects works, see [Field].
 * 
 * When using on the client side, be sure to set the redstone_mapper's
 * transformer in your pubspec.yaml.
 */ 
dynamic encode(dynamic input) {
  return defaultCodec.encode(input);
}

/**
 * The codec used by the [decode] and [encode] top level functions. 
 * 
 * This codec can be used to transfer objects between client and
 * server. It recursively encode objects to Maps and Lists, which
 * can be easily converted to json.
 * 
 * When using on the client side, be sure to set the redstone_mapper's
 * transformer in your pubspec.yaml.
 */
final GenericTypeCodec defaultCodec = new GenericTypeCodec();

/**
 * Configure the mapper system.
 * 
 * Usually, you don't need to call this method directly, since it will
 * be called by the [bootstrapMapper] method.
 */
void configure(MapperFactory mapperFactory, ValidatorFactory validatorFactory) {
  _mapperFactory = mapperFactory;  
  _validatorFactory = validatorFactory;
}

/**
 * A set of rules to validate maps and objects.
 * 
 * This class provides a simple and flexible way to
 * build a set of validation rules.
 * 
 * Usage:
 * 
 *      var userValidator = new Validator()
 *                      ..add("username", const NotEmpty())
 *                      ..add("password", const Range(min: 6. required: true));
 * 
 *      ...
 *      Map user = {"username": "user", "password": "pass"};
 *      ValidationError err = userValidator.execute(user);
 *      if (err != null) {
 *        ...
 *      }
 * 
 * To validate objects, you must provide the target class to the constructor. Also,
 * you must annotate with [Field] the members that will be validated.
 * 
 *      Class User {
 *        
 *        @Field()
 *        String username;
 *        
 *        @Field()
 *        String password;
 * 
 *      }
 * 
 *      var userValidator = new Validator(User)
 *                      ..add("username", const NotEmpty())
 *                      ..add("password", const Range(min: 6. required: true));
 * 
 *      ...
 *      User user = new User()
 *                  ..username = "user"
 *                  ..password = "pass";
 *      ValidationError err = userValidator.execute(user);
 *      if (err != null) {
 *        ...
 *      }
 * 
 * Alternatively, you can set the rules directly in the class. 
 * 
 *      Class User {
 *        
 *        @Field()
 *        @NotEmpty()
 *        String username;
 *        
 *        @Field()
 *        @Range(min: 6, required: true)
 *        String password;
 * 
 *      }
 * 
 *      var userValidator = new Validator(User, true);
 * 
 * You can also inherit from [Schema], which will provide a Validator
 * for you.
 * 
 *      Class User extends Schema {
 *        
 *        @Field()
 *        @NotEmpty()
 *        String username;
 *        
 *        @Field()
 *        @Range(min: 6, required: true)
 *        String password;
 * 
 *      }
 * 
 *      ...
 *      User user = new User()
 *                  ..username = "user"
 *                  ..password = "pass";
 *      var err = user.validate();
 *      if (err != null) {
 *        ...
 *      }
 * 
 * When using on the client side, be sure to set the redstone_mapper's
 * transformer in your pubspec.yaml.
 * 
 */ 
abstract class Validator {
  
  /**
   * Construct a new Validator.
   * 
   * If [type] is provided, then the validator will be able
   * to validate objects of type [type]. If [parseAnnotations] is
   * true, then the validator will load all rules that were specified
   * directly in the class.
   */ 
  factory Validator([Type type, bool parseAnnotations = false]) => 
      _validatorFactory(type, parseAnnotations);
  
  /**
   * Add a new [rule] to this Validator 
   * 
   * If this Validator is tied to a class, [field] must
   * be a class member. [rule] can be a instance of [NotEmpty],
   * [Range], [Matches] or [OnlyNumbers]. If you want to build
   * a custom rule, see [ValidationRule].
   *
   */
  add(String field, ValidationRule rule);
  
  /**
   * Adds all rules from [validator] to this Validator.
   */ 
  addAll(Validator validator);
  
  /**
   * Validate [obj].
   * 
   * If an error is found, returns a [ValidationError],
   * otherwise returns null.
   */
  ValidationError execute(Object obj);
  
}

///An error produced by a [Validator]. 
class ValidationError {
  
  /**
   * A Map of fields that failed the validation test.
   * 
   * For each field, this map provides the List of rules
   * that the field couldn't match.
   */ 
  @Field()
  Map<String, List<String>> invalidFields;
  
  ValidationError([this.invalidFields]) {
    if (invalidFields == null) {
      invalidFields = {};
    }
  }
  
  String toString() => "invalidFields: $invalidFields";
  
  /**
   * Add all invalid fields from [error] to this
   * [ValidationError].
   */ 
  join(ValidationError error) {
    if (error != null) {
      error.invalidFields.forEach((key, value) {
        var fieldErrors = invalidFields[key];
        if (fieldErrors == null) {
          fieldErrors = [];
          invalidFields[key] = fieldErrors;
        }
        fieldErrors.addAll(value);
      });
    }
  }
}

///A codec to convert objects of an specific type.
class TypeCodec extends Codec {
  
  final Type type;
  
  _TypeDecoder _decoder;
  _TypeEncoder _encoder;
  
  TypeCodec(this.type, {FieldDecoder fieldDecoder, 
                        FieldEncoder fieldEncoder}) {
    fieldDecoder = fieldDecoder != null ? 
        fieldDecoder : _defaultFieldDecoder;
    fieldEncoder = fieldEncoder != null ? 
        fieldEncoder : _defaultFieldEncoder;
    
    _decoder = new _TypeDecoder(fieldDecoder, type);
    _encoder = new _TypeEncoder(fieldEncoder, type);
  }
  
  @override
  Converter get decoder => _decoder;

  @override
  Converter get encoder => _encoder;
  
}

///A codec that can convert objects of any type. 
class GenericTypeCodec {
  
  _TypeDecoder _decoder;
  _TypeEncoder _encoder;
  
  GenericTypeCodec({FieldDecoder fieldDecoder, FieldEncoder fieldEncoder}) {
    fieldDecoder = fieldDecoder != null ? 
        fieldDecoder : _defaultFieldDecoder;
    fieldEncoder = fieldEncoder != null ? 
        fieldEncoder : _defaultFieldEncoder;
    
    _decoder = new _TypeDecoder(fieldDecoder);
    _encoder = new _TypeEncoder(fieldEncoder);
  }
  
  dynamic encode(dynamic input, [Type type]) {
    return _encoder.convert(input, type);
  }
  
  dynamic decode(dynamic data, Type type) {
    return _decoder.convert(data, type); 
  }
  
}

/**
 * A [FieldDecoder] is a function which can extract field
 * values from an encoded data.
 */ 
typedef Object FieldDecoder(Object encodedData, String fieldName, 
                            Field fieldInfo, List metadata);

/**
 * A [FieldEncoder] is a function which can add fields to
 * an encoded data.
 */ 
typedef void FieldEncoder(Map encodedData, String fieldName, 
                          Field fieldInfo, List metadata, Object value);


/**
 * The main mapper class, used by codecs to transform
 * objects.
 * 
 * Currently, there are two implementations of Mapper.
 * The first one uses the mirrors API, and is used when
 * the application runs on the dartvm. The second one uses
 * static data generated by the redstone_mapper's transformer,
 * and is used when the application is compiled to javascript.
 * 
 */ 
abstract class Mapper {
  
  MapperDecoder get decoder;
  
  MapperEncoder get encoder;
  
}

///decode [data] to one or more objects of type [type], using [fieldDecoder]
///to extract field values.
typedef dynamic MapperDecoder(Object data, FieldDecoder fieldDecoder, [Type type]);

///encode [obj] using [fieldEncoder] to encode field values.
typedef Map MapperEncoder(Object obj, FieldEncoder fieldEncoder);

/**
 * An exception generated when an object can't be encoded
 * or decoded.
 */ 
class MapperException implements Exception {
  
  String message;
  
  Queue<StackElement> _stack = new Queue();
  
  MapperException(String this.message);
  
  void append(StackElement element) {
    _stack.addFirst(element);
  }
  
  String _printStack() {
    if (_stack.isEmpty) {
      return "";
    }
    var stack = new StringBuffer(_stack.first.name);
    _stack.skip(1).forEach((e) {
      if (e.isType) {
        stack.write("(${e.name})");
      } else {
        stack.write("#${e.name}");
      }
    });
    stack.write(":");
    return stack.toString();
  }
  
  String toString() => "MapperException: ${_printStack()} $message";
  
}


class StackElement {
  
  final bool isType;
  final String name;
  
  StackElement(this.isType, this.name);
  
}

typedef Mapper MapperFactory(Type type);
typedef Validator ValidatorFactory([Type type, bool parseAnnotations]);

MapperFactory _mapperFactory = (Type type) => 
    throw new UnsupportedError(
        "redstone_mapper is not properly configured. Did you call bootstrapMapper()?");
ValidatorFactory _validatorFactory = ([Type type, bool parseAnnotations]) => 
    throw new UnsupportedError(
        "redstone_mapper is not properly configured. Did you call bootstrapMapper()?");
