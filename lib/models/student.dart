class Student {
  final String id;
  final String name;
  final String department;
  final String program;
  final String batch;
  final String validUntil;
  final String? photoPath;
  final String bloodGroup;
  final String contactNumber;
  final String email;

  Student({
    required this.id,
    required this.name,
    required this.department,
    required this.program,
    required this.batch,
    required this.validUntil,
    this.photoPath,
    required this.bloodGroup,
    required this.contactNumber,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'program': program,
      'batch': batch,
      'validUntil': validUntil,
      'photoPath': photoPath,
      'bloodGroup': bloodGroup,
      'contactNumber': contactNumber,
      'email': email,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      department: json['department'],
      program: json['program'],
      batch: json['batch'],
      validUntil: json['validUntil'],
      photoPath: json['photoPath'],
      bloodGroup: json['bloodGroup'],
      contactNumber: json['contactNumber'],
      email: json['email'],
    );
  }
}

