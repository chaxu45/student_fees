import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/student.dart';
import '../models/fee_payment.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        class_name TEXT NOT NULL,
        monthly_fee REAL NOT NULL,
        initial_due REAL NOT NULL DEFAULT 0,
        join_date TEXT NOT NULL,
        notes TEXT,
        last_payment_date TEXT,
        due_start_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fee_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        month TEXT NOT NULL,
        year INTEGER NOT NULL,
        notes TEXT,
        is_partial_payment INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _createTables(db, newVersion);
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Initialize for web
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        'student_fees.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // Initialize for desktop/mobile
      sqfliteFfiInit();
      var factory = databaseFactoryFfi;
      final path = join(await factory.getDatabasesPath(), 'student_fees.db');
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
        ),
      );
    }
  }

  // Student operations
  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('students');
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<Student?> getStudent(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<void> updateStudentLastPaymentDate(int studentId, DateTime paymentDate) async {
    final db = await database;
    await db.update(
      'students',
      {'last_payment_date': paymentDate.toIso8601String()},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> deleteStudent(int id) async {
    final db = await database;
    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fee payment operations
  Future<int> insertFeePayment(FeePayment payment) async {
    final db = await database;
    return await db.insert('fee_payments', payment.toMap());
  }

  Future<List<FeePayment>> getFeePayments(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fee_payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => FeePayment.fromMap(maps[i]));
  }

  Future<List<FeePayment>> getFeePaymentsByMonth(int studentId, String month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fee_payments',
      where: 'student_id = ? AND month = ? AND year = ?',
      whereArgs: [studentId, month, year],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => FeePayment.fromMap(maps[i]));
  }

  Future<double> getTotalPaidAmount(int studentId, String month, int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM fee_payments
      WHERE student_id = ? AND month = ? AND year = ?
    ''', [studentId, month, year]);
    return result.first['total'] as double? ?? 0.0;
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'student_fees.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
} 