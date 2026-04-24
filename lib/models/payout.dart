class Payout {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String method; // 'DuitNow', 'Maybank', 'CIMB', 'TNG', 'GrabPay'
  final String status; // 'Completed', 'Pending', 'Failed'
  final DateTime timestamp;
  final String? reference;

  const Payout({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.method,
    required this.status,
    required this.timestamp,
    this.reference,
  });
}
