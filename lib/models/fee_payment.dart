class FeePayment {
  final int? id;
  final int studentId;
  final double amount;
  final DateTime paymentDate;
  final String month;
  final int year;
  final String? notes;
  final bool isPartialPayment;

  FeePayment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.month,
    required this.year,
    this.notes,
    required this.isPartialPayment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'month': month,
      'year': year,
      'notes': notes,
      'is_partial_payment': isPartialPayment ? 1 : 0,
    };
  }

  factory FeePayment.fromMap(Map<String, dynamic> map) {
    return FeePayment(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      amount: map['amount'] as double,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      month: map['month'] as String,
      year: map['year'] as int,
      notes: map['notes'] as String?,
      isPartialPayment: (map['is_partial_payment'] as int) == 1,
    );
  }

  FeePayment copyWith({
    int? id,
    int? studentId,
    double? amount,
    DateTime? paymentDate,
    String? month,
    int? year,
    String? notes,
    bool? isPartialPayment,
  }) {
    return FeePayment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      month: month ?? this.month,
      year: year ?? this.year,
      notes: notes ?? this.notes,
      isPartialPayment: isPartialPayment ?? this.isPartialPayment,
    );
  }
} 