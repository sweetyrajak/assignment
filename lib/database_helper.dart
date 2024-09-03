import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'assignment.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCustomerTable(db);
  }

  Future<void> _createCustomerTable(Database db) async {
    await db.execute('''
      CREATE TABLE Customer(
        Customer_Id INTEGER PRIMARY KEY AUTOINCREMENT,
        Customer_Name TEXT,
        Mobile TEXT,
        Email TEXT,
        Address TEXT,
        Lat TEXT,
        Long TEXT,
        Geo_Address TEXT,
        Customer_Image TEXT
      )
    ''');
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    Database db = await database;
    return await db.insert('Customer', customer);
  }


  Future<List<Map<String, dynamic>>> getAttendanceRecords() async {
    Database db = await database;
    return await db.query(
      'Customer',
      orderBy: 'Customer_Id',
    );
  }

}
