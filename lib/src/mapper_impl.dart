part of redstone_mapper;

final _defaultFieldDecoder =
    (final Object encodedData, final String fieldName, final Field fieldInfo, final List metadata) {
  String name = fieldName;

  if (fieldInfo.view is String) {
    if (fieldInfo.view.isEmpty) {
      return ignoreValue;
    }

    name = fieldInfo.view;
  }

  return (encodedData as Map)[name];
};

final _defaultFieldEncoder = (final Map encodedData, final String fieldName,
    final Field fieldInfo, final List metadata, final Object value) {
  if (value == null) {
    return;
  }

  String name = fieldName;

  if (fieldInfo.view is String) {
    if (fieldInfo.view.isEmpty) {
      return;
    }

    name = fieldInfo.view;
  }

  encodedData[name] = value;
};

class _TypeDecoder extends Converter {
  final Type type;
  final FieldDecoder fieldDecoder;
  final Map<Type, Codec> typeCodecs;

  _TypeDecoder(this.fieldDecoder, {this.type, this.typeCodecs: const {}});

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

  _TypeEncoder(this.fieldEncoder, {this.type, this.typeCodecs: const {}});

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
