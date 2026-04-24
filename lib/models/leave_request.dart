class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String type; // 'Annual', 'Sick', 'Personal', 'Maternity'
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime submittedAt;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.submittedAt,
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;
}
