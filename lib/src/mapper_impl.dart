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
  
  final Type _type;
  final FieldDecoder _fieldDecoder;
  
  _TypeDecoder(this._fieldDecoder, [this._type]);
  
  @override
  convert(input, [Type type]) {
    if (type == null) {
      type = _type;
    }
    
    Mapper mapper = _mapperFactory(type);
    return mapper.decoder(input, _fieldDecoder, type);
  }
  
}

class _TypeEncoder extends Converter {
  
  final Type _type;
  final FieldEncoder _fieldEncoder;
  
  _TypeEncoder(this._fieldEncoder, [this._type]);
  
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
      if (_type == null) {
        type = input.runtimeType;
      } else {
        type = _type;
      }
    }
    
    Mapper mapper = _mapperFactory(type);
    return mapper.encoder(input, _fieldEncoder);
  }
  
}