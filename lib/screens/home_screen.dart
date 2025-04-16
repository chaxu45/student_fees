import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/student_card.dart';
import 'add_student_screen.dart';
import 'student_details_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMonth = DateTime.now().month.toString();
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    // Ensure students are loaded when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Fees'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                      final monthName = DateFormat('MMMM').format(DateTime(2024, index + 1));
                      return DropdownMenuItem(
                        value: month,
                        child: Text(monthName),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                        });
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
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Filter by Class: '),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer<StudentProvider>(
                    builder: (context, provider, child) {
                      final classes = ['All'] + provider.availableClasses;
                      return DropdownButtonFormField<String>(
                        value: provider.selectedClass,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: classes.map((className) {
                          return DropdownMenuItem(
                            value: className == 'All' ? null : className,
                            child: Text(className),
                          );
                        }).toList(),
                        onChanged: (value) {
                          provider.setSelectedClass(value);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, studentProvider, child) {
                if (studentProvider.students.isEmpty) {
                  return const Center(
                    child: Text('No students added yet'),
                  );
                }

                return FutureBuilder<List<double>>(
                  future: Future.wait(
                    studentProvider.students.map((student) async {
                      return await studentProvider.getStudentTotalPaidAmount(
                        student.id!,
                        _selectedMonth,
                        _selectedYear,
                      );
                    }),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      debugPrint('Error loading payments: ${snapshot.error}');
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final paidAmounts = snapshot.data ?? [];

                    return ListView.builder(
                      itemCount: studentProvider.students.length,
                      itemBuilder: (context, index) {
                        final student = studentProvider.students[index];
                        final paidAmount = paidAmounts[index];

                        return StudentCard(
                          student: student,
                          paidAmount: paidAmount,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentDetailsScreen(student: student),
                              ),
                            ).then((_) {
                              // Refresh the list when returning from details screen
                              studentProvider.loadStudents();
                            });
                          },
                          onDelete: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Student'),
                                content: Text('Are you sure you want to delete ${student.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true) {
                              try {
                                await studentProvider.deleteStudent(student.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${student.name} has been deleted'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to delete student'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddStudentScreen(),
            ),
          );
          if (mounted) {
            context.read<StudentProvider>().loadStudents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 