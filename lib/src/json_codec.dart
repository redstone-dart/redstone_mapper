part of redstone_mapper;

/**
 * A JSON codec. 
 * 
 * This codec can be used to transfer objects between client and
 * server. It recursively encode objects to Maps and Lists, which
 * can be easily converted to json.
 * 
 * When using on the client side, be sure to set the redstone_mapper's
 * transformer in your pubspec.yaml.
 */
final GenericTypeCodec jsonCodec = new GenericTypeCodec(typeCodecs: {
  DateTime: new Iso8601Codec()
});

///A codec to convert between DateTime objects and strings.
class Iso8601Codec extends Codec {
  
  final _decoder = new Iso8601Decoder();
  final _encoder = new Iso8601Encoder();
  
  @override
  Converter get decoder => _decoder;

  @override
  Converter get encoder => _encoder;
  
}

class Iso8601Encoder extends Converter {
  
  @override
  convert(input) => input.toIso8601String();
  
}

class Iso8601Decoder extends Converter {
  
  @override
  convert(input) => DateTime.parse(input);
  
}