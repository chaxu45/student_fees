import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/student_provider.dart';
import '../widgets/custom_text_field.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({Key? key}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  final _initialDueController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _joinDate = DateTime.now();
  DateTime? _dueStartDate;

  @override
  void dispose() {
    _nameController.dispose();
    _classNameController.dispose();
    _monthlyFeeController.dispose();
    _initialDueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isJoinDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isJoinDate ? _joinDate : (_dueStartDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isJoinDate) {
          _joinDate = picked;
        } else {
          _dueStartDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Class',
                controller: _classNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter class name';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Monthly Fee',
                controller: _monthlyFeeController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter monthly fee';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Initial Due Amount',
                controller: _initialDueController,
                keyboardType: TextInputType.number,
                hint: 'Enter initial due amount (optional)',
                isRequired: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join Date'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_joinDate.day}/${_joinDate.month}/${_joinDate.year}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Start Date'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _dueStartDate != null
                                  ? '${_dueStartDate!.day}/${_dueStartDate!.month}/${_dueStartDate!.year}'
                                  : 'Select Date',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CustomTextField(
                label: 'Notes',
                controller: _notesController,
                maxLines: 3,
                hint: 'Enter any additional notes (optional)',
                isRequired: false,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addStudent,
                child: const Text('Add Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addStudent() {
    if (_formKey.currentState!.validate()) {
      try {
        final monthlyFee = double.parse(_monthlyFeeController.text);
        final initialDue = double.tryParse(_initialDueController.text) ?? 0.0;

        final student = Student(
          name: _nameController.text,
          className: _classNameController.text,
          monthlyFee: monthlyFee,
          initialDue: initialDue,
          joinDate: _joinDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          dueStartDate: _dueStartDate,
        );

        context.read<StudentProvider>().addStudent(student);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid amounts for fees'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 