class ClaimRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String category; // 'Travel', 'Meals', 'Equipment', 'Medical', 'Other'
  final double amount;
  final DateTime receiptDate;
  final String description;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime submittedAt;

  const ClaimRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.category,
    required this.amount,
    required this.receiptDate,
    required this.description,
    required this.status,
    required this.submittedAt,
  });
}
