import 'dart:math';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/leave_request.dart';
import '../models/claim_request.dart';
import '../models/payout.dart';

class MockDataService {
  static Employee get currentEmployee => const Employee(
    id: '1', name: 'Ahmad Razif', email: 'ahmad.razif@syarikat.com.my',
    department: 'Engineering', division: 'IT', position: 'Senior Developer',
    avatarUrl: '', employeeId: 'MY-2024-001',
    monthlySalary: 8500.0, performanceScore: 92.0,
    latitude: 3.1480, longitude: 101.7130,
  );

  static List<Employee> get allEmployees => const [
    Employee(id: '1', name: 'Ahmad Razif', email: 'ahmad.razif@syarikat.com.my', department: 'Engineering', division: 'IT', position: 'Senior Developer', avatarUrl: '', employeeId: 'MY-2024-001', monthlySalary: 8500, performanceScore: 92, latitude: 3.1480, longitude: 101.7130),
    Employee(id: '2', name: 'Nurul Aisyah', email: 'nurul.aisyah@syarikat.com.my', department: 'Engineering', division: 'IT', position: 'Frontend Dev', avatarUrl: '', employeeId: 'MY-2024-002', monthlySalary: 6500, performanceScore: 88, latitude: 3.1510, longitude: 101.7100),
    Employee(id: '3', name: 'Muhammad Hafiz', email: 'hafiz@syarikat.com.my', department: 'Engineering', division: 'IT', position: 'Backend Dev', avatarUrl: '', employeeId: 'MY-2024-003', monthlySalary: 7200, performanceScore: 85, latitude: 3.1455, longitude: 101.7080),
    Employee(id: '4', name: 'Siti Aminah', email: 'siti.aminah@syarikat.com.my', department: 'Finance', division: 'Finance', position: 'Finance Manager', avatarUrl: '', employeeId: 'MY-2024-004', monthlySalary: 9200, performanceScore: 95, latitude: 3.1520, longitude: 101.7150),
    Employee(id: '5', name: 'Tan Wei Ming', email: 'weiming@syarikat.com.my', department: 'Finance', division: 'Finance', position: 'Accountant', avatarUrl: '', employeeId: 'MY-2024-005', monthlySalary: 5800, performanceScore: 78, latitude: 3.1400, longitude: 101.7050),
    Employee(id: '6', name: 'Raj Kumar', email: 'raj.kumar@syarikat.com.my', department: 'Finance', division: 'Finance', position: 'Auditor', avatarUrl: '', employeeId: 'MY-2024-006', monthlySalary: 6100, performanceScore: 82, latitude: 3.1490, longitude: 101.7110),
    Employee(id: '7', name: 'Farah Nadia', email: 'farah.nadia@syarikat.com.my', department: 'Human Resources', division: 'HR', position: 'HR Director', avatarUrl: '', employeeId: 'MY-2024-007', monthlySalary: 10500, performanceScore: 97, latitude: 3.1530, longitude: 101.7160),
    Employee(id: '8', name: 'Lim Chee Keong', email: 'chee.keong@syarikat.com.my', department: 'Human Resources', division: 'HR', position: 'Recruiter', avatarUrl: '', employeeId: 'MY-2024-008', monthlySalary: 5200, performanceScore: 74, latitude: 3.1460, longitude: 101.7090),
    Employee(id: '9', name: 'Amirul Hakim', email: 'amirul@syarikat.com.my', department: 'Human Resources', division: 'HR', position: 'Training Lead', avatarUrl: '', employeeId: 'MY-2024-009', monthlySalary: 6800, performanceScore: 86, latitude: 3.1475, longitude: 101.7120),
    Employee(id: '10', name: 'Priya Devi', email: 'priya@syarikat.com.my', department: 'Production', division: 'Production', position: 'Production Manager', avatarUrl: '', employeeId: 'MY-2024-010', monthlySalary: 8800, performanceScore: 91, latitude: 3.1380, longitude: 101.7000),
    Employee(id: '11', name: 'Zulkifli Rahman', email: 'zul@syarikat.com.my', department: 'Production', division: 'Production', position: 'Supervisor', avatarUrl: '', employeeId: 'MY-2024-011', monthlySalary: 5500, performanceScore: 79, latitude: 3.1420, longitude: 101.6980),
    Employee(id: '12', name: 'Wong Mei Ling', email: 'meiling@syarikat.com.my', department: 'Production', division: 'Production', position: 'QA Engineer', avatarUrl: '', employeeId: 'MY-2024-012', monthlySalary: 6300, performanceScore: 83, latitude: 3.1440, longitude: 101.7040),
  ];

  static List<Employee> employeesByDivision(String division) =>
      division == 'All' ? allEmployees : allEmployees.where((e) => e.division == division).toList();

  // Attendance chart data (30 days)
  static List<double> get dailyAttendancePercent => [85, 92, 88, 95, 78, 0, 0, 90, 87, 93, 96, 82, 0, 0, 88, 91, 94, 89, 86, 0, 0, 93, 90, 88, 95, 91, 0, 0, 87, 92];
  static List<double> get weeklyHours => [42, 38, 45, 40, 44, 39, 43, 41, 46, 37, 42, 40];
  static List<double> get monthlyPerformance => [78, 80, 82, 85, 83, 87, 88, 90, 92, 89, 91, 92];

  // Staff personal analytics
  static Map<String, double> get personalWeeklyHours => {'Mon': 8.5, 'Tue': 9.0, 'Wed': 7.5, 'Thu': 8.0, 'Fri': 8.5};
  static Map<String, double> get personalLastWeekHours => {'Mon': 8.0, 'Tue': 8.5, 'Wed': 9.0, 'Thu': 7.5, 'Fri': 8.0};
  static double get personalAttendanceRate => 96.5;
  static double get personalAvgHours => 8.3;
  static Map<String, double> get personalClaimBreakdown => {'Travel': 245.50, 'Meals': 87.00, 'Equipment': 1299.99, 'Medical': 0};

  static List<AttendanceRecord> get attendanceRecords => [
    AttendanceRecord(id: 'att-1', employeeId: '1', date: DateTime.now(), checkIn: DateTime.now().copyWith(hour: 8, minute: 30), status: 'present', isInGeofence: true),
    AttendanceRecord(id: 'att-2', employeeId: '1', date: DateTime.now().subtract(const Duration(days: 1)), checkIn: DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 9, minute: 15), checkOut: DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 17, minute: 30), status: 'late', isInGeofence: true),
    AttendanceRecord(id: 'att-3', employeeId: '1', date: DateTime.now().subtract(const Duration(days: 2)), checkIn: DateTime.now().subtract(const Duration(days: 2)).copyWith(hour: 8, minute: 0), checkOut: DateTime.now().subtract(const Duration(days: 2)).copyWith(hour: 17, minute: 0), status: 'present', isInGeofence: true),
  ];

  static List<LeaveRequest> get leaveRequests => [
    LeaveRequest(id: 'lv-1', employeeId: '1', employeeName: 'Ahmad Razif', type: 'Annual', startDate: DateTime.now().add(const Duration(days: 5)), endDate: DateTime.now().add(const Duration(days: 8)), reason: 'Family trip to Langkawi', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(hours: 2))),
    LeaveRequest(id: 'lv-2', employeeId: '1', employeeName: 'Ahmad Razif', type: 'Sick', startDate: DateTime.now().subtract(const Duration(days: 10)), endDate: DateTime.now().subtract(const Duration(days: 9)), reason: 'MC from Klinik Kesihatan', status: 'Approved', submittedAt: DateTime.now().subtract(const Duration(days: 11))),
    LeaveRequest(id: 'lv-3', employeeId: '1', employeeName: 'Ahmad Razif', type: 'Personal', startDate: DateTime.now().subtract(const Duration(days: 30)), endDate: DateTime.now().subtract(const Duration(days: 30)), reason: 'Pindah rumah baru', status: 'Rejected', submittedAt: DateTime.now().subtract(const Duration(days: 32))),
    LeaveRequest(id: 'lv-4', employeeId: '2', employeeName: 'Nurul Aisyah', type: 'Annual', startDate: DateTime.now().add(const Duration(days: 3)), endDate: DateTime.now().add(const Duration(days: 7)), reason: 'Balik kampung Hari Raya', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(hours: 5))),
    LeaveRequest(id: 'lv-5', employeeId: '4', employeeName: 'Siti Aminah', type: 'Sick', startDate: DateTime.now(), endDate: DateTime.now().add(const Duration(days: 1)), reason: 'Dental surgery', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(hours: 1))),
    LeaveRequest(id: 'lv-6', employeeId: '7', employeeName: 'Farah Nadia', type: 'Personal', startDate: DateTime.now().add(const Duration(days: 10)), endDate: DateTime.now().add(const Duration(days: 11)), reason: 'Attending HR conference', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(hours: 8))),
  ];

  static List<ClaimRequest> get claimRequests => [
    ClaimRequest(id: 'cl-1', employeeId: '1', employeeName: 'Ahmad Razif', category: 'Travel', amount: 245.50, receiptDate: DateTime.now().subtract(const Duration(days: 3)), description: 'Grab ride to client meeting', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(days: 1))),
    ClaimRequest(id: 'cl-2', employeeId: '1', employeeName: 'Ahmad Razif', category: 'Meals', amount: 87.00, receiptDate: DateTime.now().subtract(const Duration(days: 7)), description: 'Team lunch at Nasi Kandar', status: 'Approved', submittedAt: DateTime.now().subtract(const Duration(days: 5))),
    ClaimRequest(id: 'cl-3', employeeId: '1', employeeName: 'Ahmad Razif', category: 'Equipment', amount: 1299.99, receiptDate: DateTime.now().subtract(const Duration(days: 14)), description: 'External monitor for WFH', status: 'Rejected', submittedAt: DateTime.now().subtract(const Duration(days: 12))),
    ClaimRequest(id: 'cl-4', employeeId: '2', employeeName: 'Nurul Aisyah', category: 'Travel', amount: 520.00, receiptDate: DateTime.now().subtract(const Duration(days: 2)), description: 'Flight to Penang office', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(hours: 12))),
    ClaimRequest(id: 'cl-5', employeeId: '4', employeeName: 'Siti Aminah', category: 'Medical', amount: 350.00, receiptDate: DateTime.now().subtract(const Duration(days: 5)), description: 'Annual health checkup', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(days: 3))),
    ClaimRequest(id: 'cl-6', employeeId: '10', employeeName: 'Priya Devi', category: 'Meals', amount: 156.80, receiptDate: DateTime.now().subtract(const Duration(days: 1)), description: 'Client dinner', status: 'Pending', submittedAt: DateTime.now().subtract(const Duration(hours: 6))),
  ];

  static List<Payout> get payoutRecords => [
    Payout(id: 'pay-1', employeeId: '1', employeeName: 'Ahmad Razif', amount: 8500, method: 'DuitNow', status: 'Completed', timestamp: DateTime.now().subtract(const Duration(days: 15)), reference: 'DN-20260409-001'),
    Payout(id: 'pay-2', employeeId: '4', employeeName: 'Siti Aminah', amount: 9200, method: 'Maybank', status: 'Completed', timestamp: DateTime.now().subtract(const Duration(days: 15)), reference: 'MB-20260409-002'),
    Payout(id: 'pay-3', employeeId: '7', employeeName: 'Farah Nadia', amount: 10500, method: 'CIMB', status: 'Completed', timestamp: DateTime.now().subtract(const Duration(days: 15)), reference: 'CI-20260409-003'),
  ];

  static double get attendancePercentage => 87.5;
  static int get totalPendingClaims => claimRequests.where((c) => c.status == 'Pending').length;
  static int get onLeaveSummary => leaveRequests.where((l) => l.status == 'Approved').length;
  static int get totalPendingLeaves => leaveRequests.where((l) => l.status == 'Pending').length;
  static int get totalEmployees => allEmployees.length;

  static List<String> get divisions => ['All', 'IT', 'Finance', 'HR', 'Production'];

  // Geofenced office locations
  static const List<GeofenceLocation> authorizedLocations = [
    GeofenceLocation(
      name: 'HQ Office - KL Sentral',
      latitude: 3.004142,
      longitude: 101.533615,
      radiusMeters: 700.0,
    ),
    GeofenceLocation(
      name: 'Branch - Penang Office',
      latitude: 5.4164,
      longitude: 100.3327,
      radiusMeters: 100.0,
    ),
    GeofenceLocation(
      name: 'Branch - JB Office',
      latitude: -6.525488,
      longitude: 107.037861,
      radiusMeters: 700.0,
    ),
    GeofenceLocation(
      name: 'KFC',
      latitude: 2.933014,
      longitude: 101.638596,
      radiusMeters: 700.0,
    ),
  ];
}

class GeofenceLocation {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  const GeofenceLocation({required this.name, required this.latitude, required this.longitude, required this.radiusMeters});
}
