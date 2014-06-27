part of redstone_mapper;

/**
 * An annotation to define class members that can
 * be encoded or decoded.
 * 
 * The [view] and [model] parameters have the same purpose:
 * instruct the codec that the field has a different name
 * when the object is encoded. However, it's up to the codec
 * to decide which parameter to use.
 * 
 * For example, codecs designed to map data between the client
 * and the server, will usually read from [view]. By other hand,
 * codecs designed to map data between a database and the server,
 * will usually read from [model]. This provides a convenient way 
 * to map data between the database and the client.
 * 
 * It's important to always define the type of the class member, so
 * the codec can properly encode and decode it. If the field is a List
 * or a Map, be sure to specify its parameters. Example:
 * 
 *      class User {
 *      
 *        @Field()
 *        String name;
 *      
 *        @Field()
 *        List<Address> adresses;
 * 
 *      }
 * 
 *      class Address {
 *      
 *        @Field()
 *        String description;
 * 
 *        @Field()
 *        int number;
 * 
 *      }
 * 
 * However, it's not recommended to use other classes that have
 * type parameters, since it's not guaranteed that the codec will
 * be able to properly encode and decode it.
 * 
 * Also, every class that can be encoded or decoded must provide
 * a default constructor, with no required arguments. 
 * 
 */ 
class Field {
  
  final String model;
  final String view;
  
  const Field({this.view, this.model});

}

/**
 * A rule that can be executed by a [Validator].
 * 
 * To build a new rule, you just have to inherit from
 * [ValidationRule] and provide a [validate] method.
 * 
 * It's not strictly required to provide a const constructor, 
 * but it's necessary if you want to use the rule as an annotation.
 * 
 * See also [NotEmpty], [Range], [Matches] and [OnlyNumbers].
 */ 
abstract class ValidationRule {
  
  final String type;
  
  /**
   * construct or get a rule instance
   * 
   * [type] is a name that will be used to identify this
   * rule when a validation test fails.
   * 
   */ 
  const ValidationRule(String this.type);
  
  ///returns true if [value] is valid, false otherwise.
  bool validate(dynamic value);
  
}