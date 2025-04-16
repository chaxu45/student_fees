import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/fee_payment.dart';
import '../services/database_service.dart';

class StudentProvider with ChangeNotifier {
  final DatabaseService _db;
  List<Student> _students = [];
  String? _selectedClass;

  StudentProvider(this._db) {
    loadStudents();
  }

  List<Student> get students => _selectedClass == null 
    ? _students 
    : _students.where((student) => student.className == _selectedClass).toList();

  String? get selectedClass => _selectedClass;

  List<String> get availableClasses {
    final classes = _students.map((s) => s.className).toSet().toList();
    classes.sort();
    return classes;
  }

  void setSelectedClass(String? className) {
    _selectedClass = className;
    notifyListeners();
  }

  Future<void> loadStudents() async {
    try {
      _students = await _db.getStudents();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> addStudent(Student student) async {
    try {
      final id = await _db.insertStudent(student);
      final newStudent = student.copyWith(id: id);
      _students.add(newStudent);
      notifyListeners();
      debugPrint('Student added successfully. Total students: ${_students.length}');
    } catch (e) {
      debugPrint('Error adding student: $e');
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      await _db.updateStudent(student);
      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = student;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating student: $e');
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      await _db.deleteStudent(id);
      _students.removeWhere((student) => student.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }

  Future<List<FeePayment>> getStudentPayments(int studentId) async {
    try {
      return await _db.getFeePayments(studentId);
    } catch (e) {
      debugPrint('Error getting student payments: $e');
      return [];
    }
  }

  Future<List<FeePayment>> getStudentPaymentsByMonth(
    int studentId,
    String month,
    int year,
  ) async {
    try {
      return await _db.getFeePaymentsByMonth(studentId, month, year);
    } catch (e) {
      debugPrint('Error getting student payments by month: $e');
      return [];
    }
  }

  Future<double> getStudentTotalPaidAmount(
    int studentId,
    String month,
    int year,
  ) async {
    try {
      final payments = await getStudentPaymentsByMonth(studentId, month, year);
      return payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    } catch (e) {
      debugPrint('Error getting total paid amount: $e');
      return 0.0;
    }
  }

  Future<void> markFeesReceived(int studentId, DateTime paymentDate) async {
    try {
      final student = _students.firstWhere((s) => s.id == studentId);
      final currentMonth = paymentDate.month.toString();
      final currentYear = paymentDate.year;

      // Get existing payments for the current month
      final existingPayments = await getStudentPaymentsByMonth(
        studentId,
        currentMonth,
        currentYear,
      );

      // Calculate total paid amount for the current month
      final totalPaid = existingPayments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

      // If fees are not fully paid, add a payment for the remaining amount
      if (totalPaid < student.monthlyFee) {
        final remainingAmount = student.monthlyFee - totalPaid;
        final payment = FeePayment(
          studentId: studentId,
          paymentDate: paymentDate,
          amount: remainingAmount,
          month: currentMonth,
          year: currentYear,
          notes: 'Full payment marked as received',
          isPartialPayment: false,
        );

        await _db.insertFeePayment(payment);
      }

      // Update the student's last payment date
      await _db.updateStudentLastPaymentDate(studentId, paymentDate);
      
      final index = _students.indexWhere((s) => s.id == studentId);
      if (index != -1) {
        _students[index] = _students[index].copyWith(lastPaymentDate: paymentDate);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking fees as received: $e');
    }
  }

  Future<void> addFeePayment(FeePayment payment) async {
    try {
      await _db.insertFeePayment(payment);
      await markFeesReceived(payment.studentId, payment.paymentDate);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding fee payment: $e');
    }
  }

  Student? getStudentById(int id) {
    try {
      return _students.firstWhere((student) => student.id == id);
    } catch (e) {
      debugPrint('Error getting student by id: $e');
      return null;
    }
  }

  Future<double> getStudentTotalRemainingAmount(int studentId) async {
    try {
      final student = _students.firstWhere((s) => s.id == studentId);
      final payments = await getStudentPayments(studentId);
      final totalPaid = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
      return student.initialDue + student.monthlyFee - totalPaid;
    } catch (e) {
      debugPrint('Error calculating total remaining amount: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getStudentMonthlyPayments(int studentId) async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      
      Map<String, double> monthlyPayments = {};
      
      // Get payments for current month
      final currentMonthPaid = await getStudentTotalPaidAmount(
        studentId,
        currentMonth.toString(),
        currentYear,
      );
      monthlyPayments['$currentYear-$currentMonth'] = currentMonthPaid;
      
      // Get payments for previous months
      for (int year = currentYear; year >= currentYear - 1; year--) {
        final startMonth = year == currentYear ? 1 : currentMonth;
        final endMonth = year == currentYear ? currentMonth - 1 : 12;
        
        for (int month = startMonth; month <= endMonth; month++) {
          final monthPaid = await getStudentTotalPaidAmount(
            studentId,
            month.toString(),
            year,
          );
          monthlyPayments['$year-$month'] = monthPaid;
        }
      }
      
      return monthlyPayments;
    } catch (e) {
      debugPrint('Error getting monthly payments: $e');
      return {};
    }
  }

  Future<void> addPayment(int studentId, double amount, String month, int year) async {
    final payment = FeePayment(
      studentId: studentId,
      amount: amount,
      paymentDate: DateTime.now(),
      month: month,
      year: year,
      isPartialPayment: true,
    );

    await _db.insertFeePayment(payment);
    await _db.updateStudentLastPaymentDate(studentId, DateTime.now());
    notifyListeners();
  }
} 