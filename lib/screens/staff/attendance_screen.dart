import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_indicator.dart';
import '../../services/mock_data_service.dart';
import '../../services/geofence_service.dart';
import 'face_scan_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with TickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;
  bool _isScanning = false;
  bool _isCheckedIn = false;
  final List<Map<String, dynamic>> _logs = [
    {'type': 'Check In', 'time': '08:32 AM', 'icon': Icons.login, 'color': const Color(0xFF10B981)},
    {'type': 'Check Out', 'time': '05:45 PM', 'icon': Icons.logout, 'color': const Color(0xFFEF4444)},
  ];

  // Geofencing state
  bool _isInRange = false;
  bool _isLoadingLocation = true;
  String _locationStatus = 'Checking location...';
  String _nearestOfficeName = '';
  double _distanceToOffice = 0;
  Position? _userPosition;
  GeofenceLocation? _nearestLocation;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  // Map style for dark mode
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
  ''';

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initGeofence();
  }

  Future<void> _initGeofence() async {
    setState(() => _isLoadingLocation = true);
    final result = await GeofenceService.checkGeofence();

    if (!mounted) return;

    if (result.errorMessage != null) {
      setState(() {
        _isLoadingLocation = false;
        _isInRange = false;
        _locationStatus = result.errorMessage!;
      });
      return;
    }

    setState(() {
      _isLoadingLocation = false;
      _isInRange = result.isInRange;
      _userPosition = result.userPosition;
      _nearestLocation = result.nearestLocation;
      _distanceToOffice = result.distanceMeters;
      _nearestOfficeName = result.nearestLocation?.name ?? 'Unknown';
      _locationStatus = result.isInRange
          ? 'You are within the office area'
          : '${result.distanceMeters.toStringAsFixed(0)}m away from ${result.nearestLocation?.name ?? "office"}';
    });

    // Move camera to user position
    if (_mapController != null && _userPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
      ));
    }

    // Start listening for location updates
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (!mounted) return;

      final locations = MockDataService.authorizedLocations;
      double minDist = double.infinity;
      GeofenceLocation? nearest;

      for (final loc in locations) {
        final dist = GeofenceService.calculateDistance(
          position.latitude, position.longitude,
          loc.latitude, loc.longitude,
        );
        if (dist < minDist) {
          minDist = dist;
          nearest = loc;
        }
      }

      final inRange = nearest != null && minDist <= nearest.radiusMeters;

      setState(() {
        _userPosition = position;
        _isInRange = inRange;
        _distanceToOffice = minDist;
        _nearestLocation = nearest;
        _nearestOfficeName = nearest?.name ?? 'Unknown';
        _locationStatus = inRange
            ? 'You are within the office area'
            : '${minDist.toStringAsFixed(0)}m away from ${nearest?.name ?? "office"}';
      });
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startScan({required bool isCheckOut}) async {
    if (!_isInRange && !isCheckOut) {
      _showOutOfRangeDialog();
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FaceScanScreen(onSuccess: () {}),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (result == true && mounted) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

      setState(() {
        if (isCheckOut) {
          _isCheckedIn = false;
          _logs.add({'type': 'Check Out', 'time': timeStr, 'icon': Icons.logout, 'color': const Color(0xFFEF4444)});
        } else {
          _isCheckedIn = true;
          _logs.add({'type': 'Check In', 'time': timeStr, 'icon': Icons.login, 'color': const Color(0xFF10B981)});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${isCheckOut ? 'Check-out' : 'Check-in'} successful! ✓', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isCheckOut ? const Color(0xFFEF4444) : const Color(0xFF10B981), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showOutOfRangeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withOpacity(0.1),
              ),
              child: const Icon(Icons.location_off, color: Color(0xFFEF4444), size: 32),
            ),
            const SizedBox(height: 20),
            Text('Outside Authorized Area', textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'You are ${_distanceToOffice.toStringAsFixed(0)}m away from $_nearestOfficeName.\n\nPlease move within ${_nearestLocation?.radiusMeters.toStringAsFixed(0) ?? '50'}m of the office to check in.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: SizedBox(height: 46, child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Cancel', style: GoogleFonts.poppins(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ))),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 46, child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(ctx); _initGeofence(); },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
              ))),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Smart Check-in', style: GoogleFonts.poppins(color: onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
        Text('Face verification & geofence required', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 24),
        _mapCard(),
        const SizedBox(height: 16),
        _geofenceStatus(),
        const SizedBox(height: 16),
        _cameraPreview(),
        const SizedBox(height: 20),
        _actionButtons(),
        const SizedBox(height: 24),
        _todayLog(),
      ]),
    ));
  }

  Widget _mapCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final office = MockDataService.authorizedLocations.first;
    final userLatLng = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : LatLng(office.latitude, office.longitude);

    final Set<Marker> markers = {};
    final Set<Circle> circles = {};

    // Add office markers and geofence circles
    for (final loc in MockDataService.authorizedLocations) {
      markers.add(Marker(
        markerId: MarkerId(loc.name),
        position: LatLng(loc.latitude, loc.longitude),
        infoWindow: InfoWindow(title: loc.name, snippet: 'Radius: ${loc.radiusMeters.toInt()}m'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));

      circles.add(Circle(
        circleId: CircleId(loc.name),
        center: LatLng(loc.latitude, loc.longitude),
        radius: loc.radiusMeters,
        fillColor: _isInRange
            ? const Color(0xFF10B981).withOpacity(0.15)
            : const Color(0xFF06B6D4).withOpacity(0.1),
        strokeColor: _isInRange
            ? const Color(0xFF10B981).withOpacity(0.5)
            : const Color(0xFF06B6D4).withOpacity(0.3),
        strokeWidth: 2,
      ));
    }

    // Add user marker
    if (_userPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: userLatLng,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Icon(Icons.map_outlined, color: const Color(0xFF06B6D4), size: 20),
            const SizedBox(width: 8),
            Text('Office Location', style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15, fontWeight: FontWeight.w600,
            )),
            const Spacer(),
            if (_isLoadingLocation)
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(const Color(0xFF06B6D4)),
              )),
            if (!_isLoadingLocation)
              GestureDetector(
                onTap: _initGeofence,
                child: Icon(Icons.refresh, color: const Color(0xFF06B6D4), size: 20),
              ),
          ]),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: userLatLng, zoom: 16),
              markers: markers,
              circles: circles,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                if (isDark) {
                  controller.setMapStyle(_darkMapStyle);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _cameraPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(padding: const EdgeInsets.all(8), child: AspectRatio(aspectRatio: 3 / 4,
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          gradient: RadialGradient(
            colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
            stops: const [0, 0.6, 1]))),
        Center(child: Container(width: 140, height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(70), border: Border.all(color: (isDark ? Colors.white : const Color(0xFF94A3B8)).withOpacity(0.2), width: 1)),
          child: Icon(Icons.face, size: 80, color: (isDark ? Colors.white : const Color(0xFF94A3B8)).withOpacity(0.2)))),
        Positioned(bottom: 16, left: 0, right: 0, child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isCheckedIn ? const Color(0xFF10B981).withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(20)),
          child: Text(
            _isCheckedIn ? '✓ Face verified' : 'Ready for verification',
            style: GoogleFonts.poppins(color: _isCheckedIn ? const Color(0xFF059669) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), fontSize: 13, fontWeight: FontWeight.w500)),
        ))),
      ]))));
  }

  Widget _geofenceStatus() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingLocation) {
      return GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
            strokeWidth: 2, valueColor: AlwaysStoppedAnimation(const Color(0xFF06B6D4)),
          )),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Checking Location', style: GoogleFonts.poppins(color: onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Verifying your position...', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 12)),
          ])),
        ]));
    }

    final hasError = _locationStatus.contains('denied') || _locationStatus.contains('disabled') || _locationStatus.contains('Failed');

    return GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        GlowIndicator(isActive: _isInRange, label: _isInRange ? 'In Range' : (hasError ? 'Error' : 'Out of Range')),
        const Spacer(),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            _isInRange ? _nearestOfficeName : (hasError ? 'Location Error' : 'Not in Office Area'),
            style: GoogleFonts.poppins(color: hasError ? const Color(0xFFEF4444) : onSurface, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          Text(
            _isInRange ? 'Geofencing Active' : _locationStatus,
            style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 11),
            textAlign: TextAlign.end,
          ),
        ])),
        if (hasError) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _initGeofence,
            child: const Icon(Icons.refresh, color: Color(0xFF06B6D4), size: 20),
          ),
        ]
      ]));
  }

  Widget _actionButtons() {
    return Column(children: [
      if (!_isCheckedIn) _btn(
        label: _isInRange ? 'Check In Now' : 'Outside Office Area',
        color1: _isInRange ? const Color(0xFF22D3EE) : const Color(0xFF64748B),
        color2: _isInRange ? const Color(0xFF06B6D4) : const Color(0xFF475569),
        isOut: false,
        enabled: _isInRange,
      ),
      if (_isCheckedIn) _slideBtn(),
    ]);
  }

  double _slidePos = 0;
  Widget _slideBtn() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity, height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(builder: (ctx, box) {
        final maxW = box.maxWidth - 64;
        return Stack(children: [
          Center(child: Text('Slide to Check Out', style: GoogleFonts.poppins(color: onSurface.withOpacity(0.4), fontSize: 15, fontWeight: FontWeight.w600))),
          Positioned(left: _slidePos, child: GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() => _slidePos = (_slidePos + d.delta.dx).clamp(0, maxW)),
            onHorizontalDragEnd: (d) {
              if (_slidePos > maxW * 0.8) {
                _startScan(isCheckOut: true);
              }
              setState(() => _slidePos = 0);
            },
            child: Container(width: 64, height: 64, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFF87171), Color(0xFFEF4444)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20)),
          )),
        ]);
      }),
    );
  }

  Widget _btn({required String label, required Color color1, required Color color2, required bool isOut, bool enabled = true}) {
    return AnimatedBuilder(animation: _pulseAnim, builder: (ctx, child) =>
      Transform.scale(scale: enabled ? _pulseAnim.value : 1.0, child: child),
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 300),
        child: SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: enabled ? () => _startScan(isCheckOut: isOut) : () => _showOutOfRangeDialog(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: enabled ? [BoxShadow(color: color2.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : null,
            ),
            child: Container(alignment: Alignment.center, height: 56,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (!enabled) ...[
                  const Icon(Icons.location_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ]),
            ),
          ),
        )),
      ));
  }

  Widget _todayLog() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text("Attendance Activity", style: GoogleFonts.poppins(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700))),
      if (_logs.isEmpty) GlassCard(child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(children: [
          Icon(Icons.history, color: onSurfaceVariant.withOpacity(0.5), size: 32),
          const SizedBox(height: 8),
          Text('No activity recorded yet', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 14)),
        ]))),
      ..._logs.reversed.map((log) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: log['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(log['icon'], color: log['color'], size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log['type'], style: GoogleFonts.poppins(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
            Text('Success • Face Verified', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(log['time'], style: GoogleFonts.poppins(color: onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Today', style: GoogleFonts.poppins(color: onSurfaceVariant, fontSize: 11)),
          ]),
        ])),
      )),
    ]);
  }
}
