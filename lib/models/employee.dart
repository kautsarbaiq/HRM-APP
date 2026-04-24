class Employee {
  final String id;
  final String name;
  final String email;
  final String department;
  final String division; // 'IT', 'Finance', 'HR', 'Production'
  final String position;
  final String avatarUrl;
  final String employeeId;
  final double monthlySalary; // in RM
  final double performanceScore; // 0-100
  final double latitude;
  final double longitude;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.division,
    required this.position,
    required this.avatarUrl,
    required this.employeeId,
    this.monthlySalary = 5000.0,
    this.performanceScore = 75.0,
    this.latitude = 3.1390,
    this.longitude = 101.6869,
  });

  double get dailySalary => monthlySalary / 22; // ~22 working days
  double get hourlySalary => dailySalary / 8;
}
