## v0.2.0-beta.1+2
* Updated dependency to work with the new code_transformers version. di.dart still depends on a old one, hence the git dependency. 

## v0.1.13
* Fix transformer crash when encoding a Map or List without type parameters.

## v0.1.12
* Fix decode of Map values

## v0.1.11
* Fix: decode and encode of null value now returns null, instead of throwing an error.
* Fix: directly encoding or decoding core types (for example: decode(42, int);) does not work when compiled to javascript

## v0.1.10
* Fix decoding of inherited properties

## v0.1.9
* Updated dependencies.

**Note:** this version requires Dart 1.7 or above

## v0.1.8+1
This release includes fixes and improvements for the client-side support (thanks to [prujohn](https://github.com/prujohn) for all the feedback):


* Fix: Compilation errors when using the `view` or `model` parameters on fields.
* Fix: When compiled to javascript, the mapper can't encode or decode objects with nested lists or maps.
* Added the `encodeJson()` and `decodeJson()` top-level functions.
* Improved error handling.
* Improved documentation:
     * Fixed some typos (thanks to [sethladd](https://github.com/sethladd))
     * Added information about integration with polymer

## v0.1.7
* Widen the version constraint for `code_transformers`

## v0.1.6
* Fix: When compiled to Javascript, redstone_mapper is not decoding DateTime objects properly.
* Fix: redstone_mapper should not suppress error messages from the mirrors api.

## v0.1.5
* Fix: when mapping json objects, redstone_mapper should handle DateTime objects as ISO 8601 strings.

## v0.1.4
* Widen the version constraint for `analyzer`

## v0.1.3
* Fix: Properly handle setter methods.

## v0.1.2
* The `@Encode` annotation can now be used with groups. If a group is annotated with `@Encode`, then redstone_mapper will encode the response of all routes within the group.

## v0.1.1
* Fix: transformer is generating broken code for validators.

## v0.1.0
* First release.
