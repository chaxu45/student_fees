import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Fees',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 0,
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 0,
          shape: StadiumBorder(),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _storageKey = 'student_data';
  late SharedPreferences _prefs;

  Future<void> _loadData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final String? jsonString = _prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        setState(() {
          _students.clear();
          _students.addAll(jsonList.map((json) => Student.fromJson(json)));
        });
      }
    } catch (e) {
      _showError('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final String jsonString = jsonEncode(_students.map((s) => s.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
    } catch (e) {
      _showError('Error saving data: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  void _deleteStudent(Student student) {
    setState(() {
      _students.remove(student);
    });
    _saveData(); // Save after deleting student
  }

  void _editStudent(Student student) {
    _nameController.text = student.name;
    _classController.text = student.studentClass;
    _monthlyFeesController.text = student.monthlyFees.toString();
    _dueFeesController.text = student.dueFees.toString();
    _selectedJoiningDate = student.joiningDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _classController,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.class_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthlyFeesController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Fees',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dueFeesController,
                  decoration: const InputDecoration(
                    labelText: 'Due Fees',
                    prefixIcon: Icon(Icons.pending_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedJoiningDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedJoiningDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Joining Date'),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedJoiningDate),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() {
                  student.name = _nameController.text;
                  student.studentClass = _classController.text;
                  student.monthlyFees = double.parse(_monthlyFeesController.text);
                  student.dueFees = double.parse(_dueFeesController.text);
                  student.joiningDate = _selectedJoiningDate;
                });
                _saveData(); // Save after editing student
                _nameController.clear();
                _classController.clear();
                _monthlyFeesController.clear();
                _dueFeesController.clear();
                _selectedJoiningDate = DateTime.now();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  late Timer _timer;
  late DateTime _currentDate;
  DateTime _selectedJoiningDate = DateTime.now();
  String? _selectedClass;

  // Get unique class names for filter dropdown
  List<String> getUniqueClasses() {
    return _students
        .map((student) => student.studentClass)
        .toSet()
        .toList()
        .cast<String>()
      ..sort();
  }

  // Get filtered students based on selected class
  List<Student> getFilteredStudents() {
    if (_selectedClass == null) return _students;
    return _students
        .where((student) => student.studentClass == _selectedClass)
        .toList();
  }

  void _checkAndUpdateFees() {
    final now = DateTime.now();
    for (var student in _students) {
      // Calculate the next due date after the last update or joining date
      DateTime baseDate = student.lastFeesUpdateDate ?? student.joiningDate;
      DateTime nextDueDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
      
      // If we've passed the next due date, add monthly fees
      if (now.isAfter(nextDueDate)) {
        setState(() {
          student.dueFees += student.monthlyFees;
          student.lastFeesUpdateDate = nextDueDate;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _loadData(); // Load saved data when app starts
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentDate = DateTime.now();
        _checkAndUpdateFees(); // Check for fee updates every second
      });
    });
  }

  final List<Student> _students = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _monthlyFeesController = TextEditingController();
  final _dueFeesController = TextEditingController();

  @override
  void dispose() {
    _timer.cancel();
    _nameController.dispose();
    _classController.dispose();
    _monthlyFeesController.dispose();
    _dueFeesController.dispose();
    super.dispose();
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _classController,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.class_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthlyFeesController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Fees',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dueFeesController,
                  decoration: const InputDecoration(
                    labelText: 'Due Fees',
                    prefixIcon: Icon(Icons.pending_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedJoiningDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedJoiningDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Joining Date'),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedJoiningDate),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() {
                  double initialDueFees = double.parse(_dueFeesController.text);
                  double monthlyFees = double.parse(_monthlyFeesController.text);
                  
                  // Add first month's fees to initial due amount
                  initialDueFees += monthlyFees;
                  
                  Student student = Student(
                    name: _nameController.text,
                    studentClass: _classController.text,
                    monthlyFees: monthlyFees,
                    dueFees: initialDueFees,  // This now includes first month's fees
                    joiningDate: _selectedJoiningDate,
                    lastFeesUpdateDate: _selectedJoiningDate,
                    payments: [],
                    paidMonths: [],
                  );
                  _students.add(student);
                });
                _saveData(); // Save after adding student
                _nameController.clear();
                _classController.clear();
                _monthlyFeesController.clear();
                _dueFeesController.clear();
                _selectedJoiningDate = DateTime.now();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addPayment(Student student, {bool isMonthlyFee = false}) {
    final noteController = TextEditingController();
    final amountController = TextEditingController();
    if (isMonthlyFee) {
      amountController.text = student.monthlyFees.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMonthlyFee ? 'Mark Monthly Fee' : 'Add Payment for ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null) {
                setState(() {
                  final payment = Payment(
                    amount: amount,
                    date: DateTime.now(),
                    note: noteController.text,
                    isMonthlyFee: isMonthlyFee,
                    month: isMonthlyFee ? DateFormat('MMM yyyy').format(DateTime.now()) : '',
                  );
                  student.payments.add(payment);
                  if (isMonthlyFee) {
                    student.paidMonths.add(DateFormat('MMM yyyy').format(DateTime.now()));
                  }
                });
                _saveData(); // Save after adding payment
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StudentDetailsPage(
            student: student,
            onAddPayment: _addPayment,
            onEdit: _editStudent,
            onDelete: _deleteStudent,
          ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Fees'),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(_currentDate),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Filter by Class:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedClass,
                  hint: const Text('All Classes', style: TextStyle(color: Colors.white70)),
                  dropdownColor: Theme.of(context).colorScheme.primaryContainer,
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  underline: Container(),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...getUniqueClasses().map((className) => DropdownMenuItem<String>(
                          value: className,
                          child: Text(className),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _students.isEmpty
          ? const Center(
              child: Text('No students added yet'),
            )
          : ListView.builder(
              itemCount: getFilteredStudents().length,
              itemBuilder: (context, index) {
                final student = getFilteredStudents()[index];
                return Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentDetailsPage(
                            student: student,
                            onAddPayment: _addPayment,
                            onEdit: _editStudent,
                            onDelete: _deleteStudent,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        student.studentClass,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!student.isCurrentMonthPaid())
                                FilledButton.icon(
                                  onPressed: () => _addPayment(student, isMonthlyFee: true),
                                  icon: const Icon(Icons.calendar_month, size: 18),
                                  label: const Text('Mark Paid'),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _addPayment(student),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remaining Fees',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${student.remainingFees.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: student.remainingFees > 0
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Next Due Date',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy')
                                        .format(student.getNextDueDate()),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class Payment {
  // Factory constructor to create a Payment from JSON
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      amount: json['amount'] as double,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String,
      isMonthlyFee: json['isMonthlyFee'] as bool,
      month: json['month'] as String?,
    );
  }

  // Convert a Payment instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'isMonthlyFee': isMonthlyFee,
      'month': month,
    };
  }
  final double amount;
  final DateTime date;
  final String note;
  final bool isMonthlyFee;
  final String? month;

  Payment({
    required this.amount,
    required this.date,
    required this.note,
    this.isMonthlyFee = false,
    this.month = '',
  });
}

class Student {
  // Factory constructor to create a Student from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['name'] as String,
      studentClass: json['studentClass'] as String,
      monthlyFees: json['monthlyFees'] as double,
      dueFees: json['dueFees'] as double,
      joiningDate: DateTime.parse(json['joiningDate'] as String),
      lastFeesUpdateDate: json['lastFeesUpdateDate'] != null
          ? DateTime.parse(json['lastFeesUpdateDate'] as String)
          : null,
      payments: (json['payments'] as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList(),
      paidMonths: List<String>.from(json['paidMonths'] as List),
    );
  }

  // Convert a Student instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'studentClass': studentClass,
      'monthlyFees': monthlyFees,
      'dueFees': dueFees,
      'joiningDate': joiningDate.toIso8601String(),
      'lastFeesUpdateDate': lastFeesUpdateDate?.toIso8601String(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'paidMonths': paidMonths,
    };
  }
  String name;
  String studentClass;
  double monthlyFees;
  double dueFees;
  DateTime joiningDate;
  List<Payment> payments;
  List<String> paidMonths;
  DateTime? lastFeesUpdateDate;

  Student({
    required this.name,
    required this.studentClass,
    required this.monthlyFees,
    required this.dueFees,
    required this.joiningDate,
    this.payments = const [],
    this.paidMonths = const [],
    this.lastFeesUpdateDate,
  });

  double get totalPaid => payments.fold(0, (sum, payment) => sum + payment.amount);
  
  double get remainingFees => dueFees - totalPaid;

  bool isCurrentMonthPaid() {
    final now = DateTime.now();
    final currentMonth = DateFormat('MMM yyyy').format(now);
    
    // If it's before the joining day of the month, check previous month
    if (now.day < joiningDate.day) {
      final previousMonth = DateTime(now.year, now.month - 1, joiningDate.day);
      return paidMonths.contains(DateFormat('MMM yyyy').format(previousMonth));
    }
    
    return paidMonths.contains(currentMonth);
  }

  DateTime getNextDueDate() {
    final now = DateTime.now();
    if (now.day < joiningDate.day) {
      // Due date is this month
      return DateTime(now.year, now.month, joiningDate.day);
    } else {
      // Due date is next month
      return DateTime(now.year, now.month + 1, joiningDate.day);
    }
  }
}

class StudentDetailsPage extends StatelessWidget {
  final Student student;
  final Function(Student, {bool isMonthlyFee}) onAddPayment;
  final Function(Student) onEdit;
  final Function(Student) onDelete;

  const StudentDetailsPage({
    super.key,
    required this.student,
    required this.onAddPayment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => onEdit(student),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Student'),
                  content: Text('Are you sure you want to delete ${student.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to home
                        onDelete(student);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  student.studentClass,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Monthly Fees',
                            value: '₹${student.monthlyFees}',
                            icon: Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _InfoCard(
                            title: 'Total Paid',
                            value: '₹${student.totalPaid.toStringAsFixed(2)}',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Remaining Fees',
                            value: '₹${student.remainingFees.toStringAsFixed(2)}',
                            icon: Icons.pending_actions,
                            color: student.remainingFees > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _InfoCard(
                            title: 'Next Due',
                            value: DateFormat('dd MMM yyyy').format(student.getNextDueDate()),
                            icon: Icons.event,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: () => onAddPayment(student),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Payment'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (student.payments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payments recorded yet',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: student.payments.length,
                itemBuilder: (context, index) {
                  final payment = student.payments[student.payments.length - 1 - index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: payment.isMonthlyFee
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(
                          payment.isMonthlyFee ? Icons.calendar_month : Icons.payment,
                          color: payment.isMonthlyFee
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        payment.isMonthlyFee
                            ? 'Monthly Fee - ${payment.month}'
                            : 'Due Payment',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '₹${payment.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(payment.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (payment.note.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment.note,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

