library redstone_mapper_transformer;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:code_transformers/resolver.dart';
import 'package:barback/barback.dart';
import 'package:source_maps/refactor.dart' show TextEditTransaction;
import 'package:path/path.dart' as path;

/**
 * The redstone_mapper transformer, which replaces the default
 * mapper implementation, that relies on the mirrors API, by a 
 * static implementation, that uses data extracted at compile
 * time.
 * 
 */ 
class StaticMapperGenerator extends Transformer with ResolverTransformer {
  
  ClassElement objectType;
  
  _CollectionType collectionType;
  ClassElement fieldAnnotationClass;
  
  final _UsedLibs usedLibs = new _UsedLibs();
  final Map<String, _TypeCodecGenerator> types = {};

  String _mapperLibPrefix;
  
  StaticMapperGenerator.asPlugin(BarbackSettings settings) {
    var sdkDir = settings.configuration["dart_sdk"];
    if (sdkDir == null) {
      // Assume the Pub executable is always coming from the SDK.
      sdkDir =  path.dirname(path.dirname(Platform.executable));
    }
    resolvers = new Resolvers(sdkDir);
  }
  
  @override
  applyResolver(Transform transform, Resolver resolver) {
    
    fieldAnnotationClass = resolver.getType("redstone_mapper.Field");
    
    if (fieldAnnotationClass == null) {
      //mapper is not being used
      transform.addOutput(transform.primaryInput);
      return;
    }
    
    var dynamicApp =
        resolver.getLibraryFunction('redstone_mapper_factory.bootstrapMapper');
    if (dynamicApp == null) {
      // No dynamic mapper imports, exit.
      transform.addOutput(transform.primaryInput);
      return;
    }
    
    objectType = resolver.getType("dart.core.Object");
    collectionType = new _CollectionType(resolver);
    _mapperLibPrefix = usedLibs
        .resolveLib(resolver.getLibraryByName("redstone_mapper"));
    
    resolver.libraries
      .expand((lib) => lib.units)
      .expand((unit) => unit.types)
      .forEach((ClassElement clazz) => _scannClass(clazz));
    
    var id = transform.primaryInput.id;
    var outputFilename = "${path.url.basenameWithoutExtension(id.path)}"
        "_static_mapper.dart";
    var outputPath = path.url.join(path.url.dirname(id.path), outputFilename);
    var generatedAssetId = new AssetId(id.package, outputPath);
    
    String typesSource = types.toString();
    
    StringBuffer source = new StringBuffer();
    _writeHeader(transform.primaryInput.id, source);
    usedLibs.libs.forEach((lib) {
      if (lib.isDartCore) return;
      var uri = resolver.getImportUri(lib, from: generatedAssetId);
      source.write("import '$uri' as ${usedLibs.prefixes[lib]};\n");
    });
    _writePreamble(source);
    source.write(typesSource);
    _writeFooter(source);
    
    transform.addOutput(
        new Asset.fromString(generatedAssetId, source.toString()));
    
    var lib = resolver.getLibrary(id);
    var transaction = resolver.createTextEditTransaction(lib);
    var unit = lib.definingCompilationUnit.node;

    for (var directive in unit.directives) {
      if (directive is ImportDirective &&
          directive.uri.stringValue == 'package:redstone_mapper/mapper_factory.dart') {
        var uri = directive.uri;
        transaction.edit(uri.beginToken.offset, uri.end,
            '\'package:redstone_mapper/mapper_factory_static.dart\'');
      }
    }
    
    var dynamicToStatic =
        new _MapperDynamicToStaticVisitor(dynamicApp, transaction);
    unit.accept(dynamicToStatic);
    
    _addImport(transaction, unit,
               outputFilename, 'generated_static_mapper');
    
    var printer = transaction.commit();
    var url = id.path.startsWith('lib/')
        ? 'package:${id.package}/${id.path.substring(4)}' : id.path;
    printer.build(url);
    transform.addOutput(new Asset.fromString(id, printer.text));
  }
  
  void _writeHeader(AssetId id, StringBuffer source) {
    var libName = path.withoutExtension(id.path).replaceAll('/', '.');
    libName = libName.replaceAll('-', '_');
    source.write("library ${id.package}.$libName.generated_static_mapper;\n");
    source.write("import 'package:redstone_mapper/mapper.dart';\n");
    source.write("import 'package:redstone_mapper/mapper_factory_static.dart';\n\n");
  }
  
  void _writePreamble(StringBuffer source) {

    var defaultField = "const $_mapperLibPrefix.Field()";
    
    source.write("_encodeField(data, fieldName, mapper, value, fieldEncoder, typeCodecs, type, \n");
    source.write("             [fieldInfo = $defaultField, metadata = const [$defaultField]]) {\n");
    source.write("  if (value != null) {\n");
    source.write("    value = mapper.encoder(value, fieldEncoder, typeCodecs);\n");
    source.write("    var typeCodec = typeCodecs[type];\n");
    source.write("    value = typeCodec != null ? typeCodec.encode(value) : value;\n");
    source.write("  }\n");
    source.write("  fieldEncoder(data, fieldName, fieldInfo, metadata,\n");
    source.write("               value);\n");
    source.write("}\n\n");
    
    source.write("_decodeField(data, fieldName, mapper, fieldDecoder, typeCodecs, type, \n");
    source.write("             [fieldInfo = $defaultField, metadata = const [$defaultField]]) {\n");
    source.write("  var value = fieldDecoder(data, fieldName, fieldInfo, metadata);\n");
    source.write("  if (value != null) {\n");
    source.write("    var typeCodec = typeCodecs[type];\n");
    source.write("    value = typeCodec != null ? typeCodec.decode(value) : value;\n");
    source.write("    return mapper.decoder(value, fieldDecoder, typeCodecs);");
    source.write("  }\n");
    source.write("  return null;\n");
    source.write("}\n\n");
    
    source.write("final Map<Type, TypeInfo> types = <Type, TypeInfo>");
  }
  
  void _writeFooter(StringBuffer source) {
    source.write(";");
  }
  
  /// Injects an import into the list of imports in the file.
  void _addImport(TextEditTransaction transaction, CompilationUnit unit,
                  String uri, String prefix) {
    var last = unit.directives.where((d) => d is ImportDirective).last;
    transaction.edit(last.end, last.end, '\nimport \'$uri\' as $prefix;');
  }
  
  dynamic _scannClass(ClassElement clazz, 
                      [List<_FieldInfo> fields, 
                       Set<ClassElement> cache,
                       Map<String, int> fieldIdxs,
                       Map<String, int> accessorIdxs]) {
    
    bool rootType = false;
    if (fields == null) {
      rootType = true;
      fields = [];
    }
    if (cache == null) {
      cache = new Set();
    }
    if (fieldIdxs == null) {
      fieldIdxs = {};
    }
    if (accessorIdxs == null) {
      accessorIdxs = {};
    }

    cache.add(clazz);
    
    if (clazz.supertype != null && clazz.supertype.element != objectType && 
          !cache.contains(clazz.supertype.element)) {
      _scannClass(clazz.supertype.element, fields, cache, fieldIdxs, accessorIdxs);
    }
    
    clazz.interfaces.where((i) => !cache.contains(i.element)).forEach((i) {
      _scannClass(i.element, fields, cache, fieldIdxs, accessorIdxs);
    });
      
    clazz.fields
      .where((f) => !f.isStatic && !f.isPrivate)
      .forEach((f) => _scannField(fields, f, fieldIdxs));
    
    clazz.accessors
      .where((p) => !p.isStatic && !p.isPrivate)
      .forEach((p) => _scannAccessor(fields, p, accessorIdxs));
    
    if (rootType) {
      if (fields.isNotEmpty) {
        var key = usedLibs.resolveLib(clazz.library);
        if (key.isNotEmpty) {
          key = "$key.$clazz";
        } else {
          key = "$clazz";
        }
        types[key] = new _TypeCodecGenerator(collectionType, usedLibs, 
                                             key, fields);
      }
      return null;
    }
    return fields;
  }

  List<String> _extractArgs(String source, String name) {
    source = source.substring(0, source.lastIndexOf(new RegExp("\\s$name")));

    var idx = source.lastIndexOf(new RegExp("[@\)]"));
    if (idx == -1) {
      return [];
    }

    var char = source[idx];
    if (char == ")") {
      source = source.substring(0, idx + 1);
    } else {
      idx = source.indexOf("\s", idx);
      source = source.substring(0, idx);
    }

    return source.split(new RegExp(r"\s@")).map((m) {
      if (m[m.length - 1] == ")") {
        return m.substring(m.indexOf("("));
      }
      return m;
    }).toList(growable: false);
  }
  
  bool _isFieldConstructor(ElementAnnotation m) =>
    m.element is ConstructorElement && (
        m.element.enclosingElement == fieldAnnotationClass ||
        (m.element.enclosingElement as ClassElement).allSupertypes.
        map((i) => i.element).contains(fieldAnnotationClass));


  _FieldMetadata _buildMetadata(Element element) {
    String source;
    if (element is FieldElement) {
      source = element.node.parent.parent.toSource();
    } else {
      source = element.node.toSource();
    }

    List<String> args = _extractArgs(source, element.displayName);

    //For fields with default configuration, don't generate metadata code
    if (args.length == 1 && args[0] == "()" && element.metadata.length == 1) {
      return null;
    }

    String fieldExp;
    List<String> exps = [];
    
    int idx = 0;
    for (ElementAnnotation m in element.metadata) {
      var prefix = usedLibs.resolveLib(m.element.library);
      if (prefix.isNotEmpty) {
        prefix += ".";
      }

      if (m.element is ConstructorElement) {
        var className = m.element.enclosingElement.displayName;
        var constructor = m.element.displayName;
        if (constructor.isNotEmpty) {
          constructor = ".$constructor";
        }
        var exp = "const $prefix$className$constructor${args[idx]}";
        exps.add(exp);
        if (fieldExp == null && _isFieldConstructor(m)) {
          fieldExp = exp;
        }
      } else {
        exps.add("$prefix${args[idx]}");
      }
    
      idx++;
    }
    
    return new _FieldMetadata(fieldExp, exps);
  }
  
  void _scannField(List<_FieldInfo> fields, FieldElement element, Map<String, int> fieldIdxs) {
    var field = element.metadata
                  .firstWhere((f) => _isFieldConstructor(f), orElse: () => null);
    if (field != null) {
      var idx = fieldIdxs[element.displayName];
      if (idx != null) {
        fields.removeAt(idx);
      }

      var metadata = _buildMetadata(element);
      fields.add(new _FieldInfo(element.displayName, element.type, 
                                metadata, canDecode: !element.isFinal));

      fieldIdxs[element.displayName] = fields.length - 1;
    }
  }
  
  void _scannAccessor(List<_FieldInfo> fields, 
                      PropertyAccessorElement element,
                      Map<String, int> accessorIdxs) {
    var field = element.metadata
                  .firstWhere((f) => _isFieldConstructor(f), orElse: () => null);
    if (field != null) {
      var metadata = _buildMetadata(element);
      var name = element.displayName;
      var type;
      var idx;
      if (element.isSetter) {
        name = name.substring(0, name.length - 1);

        idx = accessorIdxs[name];
        if (idx != null) {
          fields.removeAt(idx);
        }

        type = element.type.normalParameterTypes[0];
      } else {
        idx = accessorIdxs[name];
        if (idx != null) {
          fields.removeAt(idx);
        }

        type = element.returnType;
      }
      fields.add(new _FieldInfo(element.displayName, type, metadata,
                                canDecode: element.isSetter,
                                canEncode: element.isGetter));

      accessorIdxs[name] = fields.length - 1;
    }
  }
  
}

class _TypeCodecGenerator {
  
  final _UsedLibs usedLibs;
  final _CollectionType collectionType;
  
  final String className;
  final List<_FieldInfo> fields;
  
  _TypeCodecGenerator(this.collectionType, this.usedLibs, 
                      this.className, this.fields);
  
  String toString() {
    var source = new StringBuffer("new TypeInfo(");
    
    _buildEncoder(source);
    source.write(", ");
    _buildDecoder(source);
    source.write(", ");
    _buildFields(source);
    source.write(")");
    
    return source.toString();
  }
  
  void _buildEncoder(StringBuffer source) {
    source.write("(obj, factory, fieldEncoder, typeCodecs) {\n");
    source.write("  var data = {};\n");
    
    fields.where((f) => f.canEncode).forEach((f) {
      var typeName = _getTypeName(f.type);
      
      source.write("  _encodeField(data, '${f.name}', ");
      _buildMapper(source, f.type, typeName);
      source.write(", obj.${f.name}, fieldEncoder, typeCodecs, $typeName");

      if (f.metadata != null) {
        var fieldExp = f.metadata.fieldExp;
        var exps = f.metadata.exps;
        source.write(", $fieldExp, $exps");
      }

      source.write(");\n");
    });
    
    source.write("  return data;\n  }");
  }
  
  void _buildDecoder(StringBuffer source) {
    source.write("(data, factory, fieldDecoder, typeCodecs) {\n");
    source.write("  var obj = new ${className}();\n");
    source.write("  var value;\n");
    
    fields.where((f) => f.canDecode).forEach((f) {
      var typeName = _getTypeName(f.type);
      
      source.write("  value = _decodeField(data, '${f.name}',");
      _buildMapper(source, f.type, typeName);
      source.write(", fieldDecoder, typeCodecs, $typeName");

      if (f.metadata != null) {
        var fieldExp = f.metadata.fieldExp;
        var exps = f.metadata.exps;
        source.write(", $fieldExp, $exps");
      }

      source.write(");\n");
      source.write("  if (value != null) {\n");
      source.write("     obj.${f.name} = value;\n");
      source.write("  }\n");
    });
    
    source.write("  return obj;\n  }");
  }
  
  void _buildFields(StringBuffer source) {
    source.write("{");
    fields.where((f) => f.canEncode).forEach((f) {
      source.write("'${f.name}': new FieldWrapper((obj) => obj.${f.name}");
      if (f.metadata != null) {
        source.write(", ${f.metadata.exps}");
      }
      source.write("),");
    });
    
    source.write("}");
  }
  
  String _getTypeName(DartType type) {
    String typePrefix = "";
    String typeName;
        
    if (type.element != null && !type.isDynamic) {
      typePrefix = usedLibs.resolveLib(type.element.library);
    }
    if (typePrefix.isNotEmpty) {
      typeName = "$typePrefix.${type.name}";
    } else {
      typeName = "${type.name}";
    }
    
    return typeName;
  }
  
  void _buildMapper(StringBuffer source, DartType type, String typeName) {
    if (type.isDynamic) {
      source.write("factory(null, encodable: false)");
    } else if (collectionType.isList(type)) {
      if (type is ParameterizedType) {
        var pType = type as ParameterizedType;
        if (pType.typeArguments.isNotEmpty) {
          var paramType = pType.typeArguments[0];
          var paramTypeName = _getTypeName(paramType);
          source.write("factory(null, isList: true, wrap: ");
          _buildMapper(source, paramType, paramTypeName);
          source.write(")");
        } else {
          source.write("factory(null, isList: true, wrap: factory(Object))");
        }
      } else {
        source.write("factory(null, isList: true, wrap: factory(Object))");
      }
    } else if (collectionType.isMap(type)) {
      if (type is ParameterizedType) {
        var pType = type as ParameterizedType;
        if (pType.typeArguments.isNotEmpty) {
          var paramType = pType.typeArguments[1];
          var paramTypeName = _getTypeName(paramType);
          source.write("factory($typeName, isMap: true, wrap: ");
          _buildMapper(source, paramType, paramTypeName);
          source.write(")");
        } else {
          source.write("factory(null, isMap: true, wrap: factory(Object))");
        }
      } else {
        source.write("factory(null, isMap: true, wrap: factory(Object))");
      }
    } else {
      if (type.element.library.isDartCore) {
        source.write("factory(null, encodable: false)");
      } else {
        source.write("factory($typeName)");
      }
    }
  }
}

class _UsedLibs {
  
  final Set<LibraryElement> libs = new Set();
  final Map<LibraryElement, String> prefixes = {};
  
  String resolveLib(LibraryElement lib) {
    libs.add(lib);
    var prefix = prefixes[lib];
    if (prefix == null) {
      prefix = lib.isDartCore ? "" : "import_${prefixes.length}";
      prefixes[lib] = prefix;
    }
    return prefix;
  }
  
}

class _CollectionType {
  
  ClassElement listType;
  ClassElement mapType;
  
  _CollectionType(Resolver resolver) {
    listType = resolver.getType("dart.core.List");
    mapType = resolver.getType("dart.core.Map");
  }
  
  bool isList(DartType type) =>
    type.element is ClassElement &&
        (type.element == listType ||
          (type.element as ClassElement).allSupertypes
          .map((i) => i.element).contains(listType));
  
  bool isMap(DartType type) =>
    type.element is ClassElement &&
        (type.element == mapType ||
          (type.element as ClassElement).allSupertypes
          .map((i) => i.element).contains(mapType));
  
}

class _FieldMetadata {
  
  final String fieldExp;
  final List<String> exps;
  
  _FieldMetadata(this.fieldExp, this.exps);
  
}

class _FieldInfo {
  
  final String name;
  final _FieldMetadata metadata;
  final DartType type;
  final bool canEncode;
  final bool canDecode;
  
  _FieldInfo(this.name, this.type, this.metadata, 
             {this.canDecode: true, this.canEncode: true});
  
}

class _MapperDynamicToStaticVisitor extends GeneralizingAstVisitor {
  final Element mapperDynamicFn;
  final TextEditTransaction transaction;
  _MapperDynamicToStaticVisitor(this.mapperDynamicFn, this.transaction);

  visitMethodInvocation(MethodInvocation m) {
    if (m.methodName.bestElement == mapperDynamicFn) {
      transaction.edit(m.methodName.beginToken.offset,
          m.methodName.endToken.end, 'staticBootstrapMapper');

      var args = m.argumentList;
      transaction.edit(args.beginToken.offset + 1, args.end - 1,
        'generated_static_mapper.types');
    }
    super.visitMethodInvocation(m);
  }
}