class Student {
  final int? id;
  final String name;
  final String className;
  final double monthlyFee;
  final double initialDue;
  final DateTime joinDate;
  final String? notes;
  final DateTime? lastPaymentDate;
  final DateTime? dueStartDate;

  Student({
    this.id,
    required this.name,
    required this.className,
    required this.monthlyFee,
    required this.initialDue,
    required this.joinDate,
    this.notes,
    this.lastPaymentDate,
    this.dueStartDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'class_name': className,
      'monthly_fee': monthlyFee,
      'initial_due': initialDue,
      'join_date': joinDate.toIso8601String(),
      'notes': notes,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'due_start_date': dueStartDate?.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      name: map['name'] as String,
      className: map['class_name'] as String,
      monthlyFee: map['monthly_fee'] as double,
      initialDue: (map['initial_due'] as num?)?.toDouble() ?? 0.0,
      joinDate: DateTime.parse(map['join_date'] as String),
      notes: map['notes'] as String?,
      lastPaymentDate: map['last_payment_date'] != null
          ? DateTime.parse(map['last_payment_date'] as String)
          : null,
      dueStartDate: map['due_start_date'] != null
          ? DateTime.parse(map['due_start_date'] as String)
          : null,
    );
  }

  Student copyWith({
    int? id,
    String? name,
    String? className,
    double? monthlyFee,
    double? initialDue,
    DateTime? joinDate,
    String? notes,
    DateTime? lastPaymentDate,
    DateTime? dueStartDate,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      className: className ?? this.className,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      initialDue: initialDue ?? this.initialDue,
      joinDate: joinDate ?? this.joinDate,
      notes: notes ?? this.notes,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      dueStartDate: dueStartDate ?? this.dueStartDate,
    );
  }
} 