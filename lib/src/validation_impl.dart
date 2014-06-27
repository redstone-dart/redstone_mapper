part of redstone_mapper;

/**
 * Provides a default [Validator] instance.
 * 
 * Usage:
 * 
 *     Class User extends Schema {
 *        
 *       @Field()
 *       @NotEmpty()
 *       String username;
 *        
 *       @Field()
 *       @Range(min: 6, required: true)
 *       String password;
 * 
 *     }
 * 
 *     ...
 *     User user = new User()
 *                  ..username = "user"
 *                  ..password = "pass";
 *     var err = user.validate();
 *     if (err != null) {
 *       ...
 *     }
 * 
 * 
 */ 
abstract class Schema {
  
  Validator _validator;
  
  Schema() {
    _validator = _validatorFactory(runtimeType, true);
  }
  
  ///validate this object. 
  ValidationError validate() => _validator.execute(this);
  
}

/**
 * Provides a convenient way to join the result of two
 * or more [Validator]s.
 * 
 * If all elements of [errors] are null or empty, then
 * this function will return null. Otherwise, a [ValidationError]
 * with all errors found will be returned.
 */ 
ValidationError joinErrors(List<ValidationError> errors) {
  var err = new ValidationError();
  err = errors.fold(err, (prevError, error) =>
      error == null ? prevError : prevError..join(error));
  return err.invalidFields.isNotEmpty ? err : null;
}

/**
 * An exception generated when an object can't
 * be validated.
 * 
 */ 
class ValidationException implements Exception {
  
  String message;
  
  ValidationException(String this.message);
  
  String toString() => "ValidationException: $message";
  
}


/**
 * Validates if a value is not empty.
 * 
 * If the value is a String, then this rule will return
 * the result of the following expression:
 * 
 *      value != null && value.trim().isNotEmpty;
 * 
 * If the value is an Iterable, then it will return:
 * 
 *      value != null && value.isNotEmpty;
 * 
 * For other types:
 * 
 *      value != null;
 * 
 */ 
class NotEmpty extends ValidationRule {
  
  const NotEmpty() : super("notEmpty");

  @override
  bool validate(value) {
    return value != null && 
        (value is! String || value.trim().isNotEmpty) &&
        (value is! Iterable || value.isNotEmpty);
  }
}

/**
 * Validates if a value is within a specific range.
 * 
 * If the value is a number, then this rule will validate
 * the value itself. If the value is a String or an Iterable, 
 * then it will validate its length. For other types, it will 
 * return false.
 * 
 * By default, this rule will return true to null values. If you want
 * to change this, you can set [required] to true.
 */ 
class Range extends ValidationRule {
  
  final num min;
  final num max;
  final bool required;
  
  const Range({num this.min, num this.max, bool this.required: false}) : super("range");
  
  @override
  bool validate(value) {
    if (value == null) {
      return !required;
    } else if (value is num) {
      return (min == null || min <= value) && (max == null || value <= max);
    } else if (value is String || value is Iterable) {
      int l = value.length;
      return (min == null || min <= l) && (max == null || l <= max);
    }
    return false;
  }
}

/**
 * Validates if a value matches a specific regex.
 * 
 * If value is a String, then this rule will return true
 * if the value matches the provided regex. Otherwise, it 
 * will return false.
 * 
 * By default, this rule will return true to null values. If you want
 * to change this, you can set [required] to true.
 */ 
class Matches extends ValidationRule {
  
  final String regexPattern;
  final bool required;
  
  const Matches(String this.regexPattern, {bool this.required: false}) : super("matches");
  
  @override
  bool validate(value) {
    if (value == null) {
      return !required;
    } else if (value is String) {
      if (!required && value.trim().isEmpty) {
        return true;
      }
      var match = new RegExp(regexPattern).firstMatch(value);
      return match != null && match[0] == value;
    }
    return false;
  }
}

/**
 * Validates if a value contains only numbers.
 * 
 * If value is a String, then this rule will return true
 * if the value contains only digit characters. Otherwise,
 * it will return false.
 * 
 */ 
class OnlyNumbers extends Matches {
  
  const OnlyNumbers({bool required: false}) : 
      super(r'\d+', required: required);
  
}