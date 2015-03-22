library redstone_mapper_plugin;

import 'package:redstone/redstone.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:di/di.dart';

import 'package:redstone_mapper/database.dart';
import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';

/**
 * An annotation to define a target parameter.
 * 
 * Parameters annotated with this annotation
 * can be decoded from the request's body or
 * query parameters.
 * 
 * [from] are the body types accepted by this target, and defaults to JSON.
 * If [fromQueryParams] is true, then this parameter will be decoded from
 * the query parameters.
 * 
 * Example:
 * 
 *     @app.Route('/services/users/add', methods: const[app.POST])
 *     addUser(@Decode() User user) {
 *       ...
 *     }
 */ 
class Decode {
  
  final List<String> from;
  final bool fromQueryParams;
  
  const Decode({List<String> this.from: const [JSON], 
                bool this.fromQueryParams: false});
  
}

/**
 * An annotation to define routes whose response
 * can be encoded.
 * 
 * Example:
 * 
 *     @app.Route('/services/users/list')
 *     @Encode()
 *     List<User> listUsers() {
 *       ...
 *     }
 * 
 */ 
class Encode {
  
  const Encode();
  
}

/**
 * Get and configure the redstone_mapper plugin.
 * 
 * If [db] is provided, then the plugin will initialize a database connection for
 * every request, and save it as a request attribute. If [dbPathPattern] is 
 * provided, then the database connection will be initialized only for routes
 * that match the pattern.
 * 
 * For more details about database integration, see the 
 * [redstone_mapper_mongo](https://github.com/luizmineo/redstone_mapper_mongo)
 * and [redstone_mapper_pg](https://github.com/luizmineo/redstone_mapper_pg) packages.
 * 
 * Usage:
 *      
 *      import 'package:redstone/server.dart' as app;
 *      import 'package:redstone_mapper/plugin.dart';
 * 
 *      main() {
 *        
 *        app.addPlugin(getMapperPlugin());
 *        ...
 *        app.start();
 * 
 *      }
 * 
 */ 
RedstonePlugin getMapperPlugin([DatabaseManager db, String dbPathPattern = r'/.*']) {
  
  return (Manager manager) {
    
    bootstrapMapper();
    
    if (db != null) {
      
      var conf = new Interceptor(dbPathPattern);
      var dbInterceptor = (Injector injector, Request request) async {
        var conn = await db.getConnection();
        request.attributes["dbConn"] = conn;
        return await chain.next();
      };
      
      manager.addInterceptor(conf, "database connection manager", 
          dbInterceptor);
      
    }
    
    manager.addParameterProvider(Decode, (dynamic metadata, Type paramType,
        String handlerName, String paramName, Request request, Injector injector) {
      
      var data;
      if (metadata.fromQueryParams) {
        var params = request.queryParameters;
        data = {};
        params.forEach((String k, List<String> v) {
          data[k] = v[0];
        });
      } else { 
        if (!metadata.from.contains(request.bodyType)) {
          throw new ErrorResponse(400, 
              "$handlerName: ${request.bodyType} not supported for this handler");
        }
        data = request.body;
      }
      
      try {
        return decode(data, paramType);
      } catch (e) {
        throw new ErrorResponse(400, "$handlerName: Error parsing '$paramName' parameter: $e");
      }
      
    });
    
    manager.addResponseProcessor(Encode, (metadata, handlerName, 
        response, injector) {
      
      if (response == null || response is shelf.Response) {
        return response;
      }
      
      return encode(response);
      
    }, includeGroups: true);
  };
  
}