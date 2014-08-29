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
