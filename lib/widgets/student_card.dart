import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../providers/student_provider.dart';
import '../screens/student_details_screen.dart';
import '../theme/app_theme.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final double paidAmount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StudentCard({
    Key? key,
    required this.student,
    required this.paidAmount,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final remainingAmount = student.initialDue + student.monthlyFee - paidAmount;
    final isPaid = paidAmount >= student.monthlyFee;
    final isPartial = paidAmount > 0 && paidAmount < student.monthlyFee;
    final status = isPaid ? 'Paid' : (isPartial ? 'Partial' : 'Due');
    final statusColor = isPaid
        ? Colors.green
        : (isPartial ? Colors.orange : Colors.red);

    return FutureBuilder<double>(
      future: context.read<StudentProvider>().getStudentTotalRemainingAmount(student.id!),
      builder: (context, snapshot) {
        final totalRemaining = snapshot.data ?? 0.0;
        final hasOverdue = totalRemaining > remainingAmount;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).cardColor.withOpacity(0.95),
                ],
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsScreen(student: student),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Class: ${student.className}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (onEdit != null || onDelete != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onEdit != null)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: onEdit,
                                  tooltip: 'Edit Student',
                                ),
                              if (onDelete != null)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: onDelete,
                                  tooltip: 'Delete Student',
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentRow(
                      context,
                      'Monthly Fee:',
                      currencyFormat.format(student.monthlyFee),
                      Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    _buildPaymentRow(
                      context,
                      'Paid Amount:',
                      currencyFormat.format(paidAmount),
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPaymentRow(
                      context,
                      'Remaining:',
                      currencyFormat.format(remainingAmount),
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: remainingAmount > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasOverdue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Total Due: ${currencyFormat.format(totalRemaining)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Date: ${DateFormat('MMM d, y').format(student.joinDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentRow(
    BuildContext context,
    String label,
    String value,
    TextStyle? style,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style,
        ),
        Text(
          value,
          style: style,
        ),
      ],
    );
  }

  void _showMarkFeesReceivedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Fees Received'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student.name}'),
            const SizedBox(height: 8),
            Text('Monthly Fee: ${NumberFormat.currency(symbol: '₹').format(student.monthlyFee)}'),
            const SizedBox(height: 16),
            const Text('Are you sure you want to mark the fees as received?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StudentProvider>().markFeesReceived(
                    student.id!,
                    DateTime.now(),
                  );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) {
      onDelete!();
    }
  }
} 