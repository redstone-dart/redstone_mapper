part of redstone_mapper;

final _defaultFieldDecoder = (Object encodedData, String fieldName, 
                              Field fieldInfo, List metadata) {
  var name = fieldInfo.view != null ? fieldInfo.view : fieldName;
  return (encodedData as Map)[name];
};

final _defaultFieldEncoder = (Map encodedData, String fieldName, 
                              Field fieldInfo, List metadata, Object value) {
  if (value != null) {
    var name = fieldInfo.view != null ? fieldInfo.view : fieldName;
    encodedData[name] = value;
  }
};

class _TypeDecoder extends Converter {
  
  final Type type;
  final FieldDecoder fieldDecoder;
  final Map<Type, Codec> typeCodecs;
  
  _TypeDecoder(this.fieldDecoder, {this.type, this.typeCodecs: const {} });
  
  @override
  convert(input, [Type type]) {
    if (type == null) {
      type = this.type;
    }
    
    Mapper mapper = _mapperFactory(type);
    return mapper.decoder(input, fieldDecoder, typeCodecs, type);
  }
  
}

class _TypeEncoder extends Converter {
  
  final Type type;
  final FieldEncoder fieldEncoder;
  final Map<Type, Codec> typeCodecs;
  
  _TypeEncoder(this.fieldEncoder, {this.type, this.typeCodecs: const {} });
  
  @override
  convert(input, [Type type]) {
    
    if (input is List) {
      return input.map((data) => _convert(data, type)).toList();
    } else if (input is Map) {
      var encodedMap = {};
      input.forEach((key, value) {
        encodedMap = _convert(value, type);
      });
      return encodedMap;
    } else {
      return _convert(input, type);
    }
  }
  
  _convert(input, Type type) {
    if (type == null) {
      if (this.type == null) {
        type = input.runtimeType;
      } else {
        type = this.type;
      }
    }
    
    Mapper mapper = _mapperFactory(type);
    return mapper.encoder(input, fieldEncoder, typeCodecs);
  }
  
}