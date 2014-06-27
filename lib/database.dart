library redstone_mapper_database;

import 'dart:async';

///Manage connections with a database. 
abstract class DatabaseManager<T> {
  
  Future<T> getConnection();
    
  void closeConnection(T connection, {dynamic error});
  
}