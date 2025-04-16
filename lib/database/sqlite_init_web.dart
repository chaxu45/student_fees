import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';

Future<void> initializeSqliteForWeb() async {
  // Initialize databaseFactory with the web implementation
  var factory = databaseFactoryFfiWeb;
  databaseFactory = factory;
  
  // Optional: You can also set some configurations here
  await factory.setDatabasesPath('/sqlite_db');
}
