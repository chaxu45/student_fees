import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/fee_payment.dart';
import '../providers/student_provider.dart';
import '../widgets/custom_text_field.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;

  const StudentDetailsScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _selectedMonth = DateTime.now().month.toString();
  int _selectedYear = DateTime.now().year;
  double _totalPaidAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTotalPaidAmount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalPaidAmount() async {
    final totalPaid = await context.read<StudentProvider>().getStudentTotalPaidAmount(
      widget.student.id!,
      _selectedMonth,
      _selectedYear,
    );
    setState(() {
      _totalPaidAmount = totalPaid;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _addPayment() {
    if (_formKey.currentState!.validate()) {
      final payment = FeePayment(
        studentId: widget.student.id!,
        paymentDate: _paymentDate,
        amount: double.parse(_amountController.text),
        month: _selectedMonth,
        year: _selectedYear,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isPartialPayment: double.parse(_amountController.text) < widget.student.monthlyFee,
      );

      context.read<StudentProvider>().addFeePayment(payment);
      _amountController.clear();
      _notesController.clear();
      _loadTotalPaidAmount();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final remainingAmount = widget.student.monthlyFee - _totalPaidAmount;
    final isFullyPaid = remainingAmount <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class: ${widget.student.className}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Fee: ${currencyFormat.format(widget.student.monthlyFee)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isFullyPaid ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isFullyPaid ? 'Paid' : 'Due',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Date: ${DateFormat('MMM d, y').format(widget.student.joinDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.student.notes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Notes: ${widget.student.notes}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const Divider(height: 24),
                    Text(
                      'Fee Summary for ${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, int.parse(_selectedMonth)))}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Fee:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          currencyFormat.format(widget.student.monthlyFee),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paid Amount:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          currencyFormat.format(_totalPaidAmount),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          currencyFormat.format(remainingAmount),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: remainingAmount > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Payment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (index) {
                            final month = (index + 1).toString();
                            return DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMonth = value;
                              });
                              _loadTotalPaidAmount();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(5, (index) {
                            final year = DateTime.now().year - 2 + index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedYear = value;
                              });
                              _loadTotalPaidAmount();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Amount',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    hint: 'Enter payment amount',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'Payment Date',
                    controller: TextEditingController(
                      text: DateFormat('MMM d, y').format(_paymentDate),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  CustomTextField(
                    label: 'Notes',
                    controller: _notesController,
                    hint: 'Enter any additional notes',
                    maxLines: 2,
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _addPayment,
                      child: const Text('Add Payment'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<FeePayment>>(
              future: context.read<StudentProvider>().getStudentPaymentsByMonth(
                    widget.student.id!,
                    _selectedMonth,
                    _selectedYear,
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final payments = snapshot.data ?? [];

                if (payments.isEmpty) {
                  return const Center(
                    child: Text('No payments recorded for this month'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          currencyFormat.format(payment.amount),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${DateFormat('MMM d, y').format(payment.paymentDate)}',
                            ),
                            if (payment.notes != null)
                              Text('Notes: ${payment.notes}'),
                          ],
                        ),
                        trailing: payment.isPartialPayment
                            ? const Chip(
                                label: Text('Partial'),
                                backgroundColor: Colors.orange,
                              )
                            : const Chip(
                                label: Text('Full'),
                                backgroundColor: Colors.green,
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 