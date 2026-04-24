class AttendanceRecord {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status; // 'present', 'late', 'absent'
  final bool isInGeofence;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.isInGeofence = true,
  });
}
