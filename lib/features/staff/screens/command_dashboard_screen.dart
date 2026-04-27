import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/theme_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../shared/widgets/coral_bottom_nav.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/theme_notifier.dart';
import '../../../core/services/assignment_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/incident_model.dart';
import '../../../core/models/staff_model.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/incident_card.dart';
import 'package:vibration/vibration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'analytics_dashboard_screen.dart';
import 'audit_log_screen.dart';
import '../../../core/services/nearby_service.dart';
import '../widgets/verification_overlay.dart';
import '../../../core/providers/incident_provider.dart';
import '../../../core/providers/connectivity_provider.dart';

class CommandDashboardScreen extends StatefulWidget {
  const CommandDashboardScreen({super.key});

  @override
  _CommandDashboardScreenState createState() => _CommandDashboardScreenState();
}

class _CommandDashboardScreenState extends State<CommandDashboardScreen> {
  int _currentIndex = 0;
  Timer? _escalationTimer;
  final AssignmentService _assignmentService = AssignmentService();
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  final Set<String> _seenIncidentIds = {};
  bool _isNearbyActive = false;
  
  // Fix B & D State
  DateTime? _lastPingTime;
  final List<IncidentModel> _pendingBanners = [];
  bool _isShowingBanner = false;
  IncidentModel? _currentBannerIncident;

  // Default position if no incidents (New Delhi / Hotel Location)
  static const CameraPosition _defaultPos = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _startEscalationWatcher();
    _initEmergencyListener();
  }

  void _initEmergencyListener() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    
    // Fix B: Heartbeat listener
    firestore.pingStream().listen((_) {
      if (mounted) setState(() => _lastPingTime = DateTime.now());
    });

    firestore.streamActiveIncidents().listen((incidents) {
      if (incidents.isNotEmpty) {
        final newest = incidents.first;
        // Only trigger scream if brand new
        if (DateTime.now().difference(newest.createdAt).inSeconds < 10 && !_seenIncidentIds.contains(newest.id)) {
           // _triggerScreamingAlert(newest); // Keep this if you want the full screen scream
        }
      }
    });
  }

  void _showNextBanner() async {
    if (_isShowingBanner || _pendingBanners.isEmpty) return;

    setState(() {
      _isShowingBanner = true;
      _currentBannerIncident = _pendingBanners.removeAt(0);
    });

    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() {
        _isShowingBanner = false;
        _currentBannerIncident = null;
      });
      // Show next if any
      Future.delayed(const Duration(milliseconds: 500), _showNextBanner);
    }
  }

  void _triggerScreamingAlert(IncidentModel incident) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
          pattern: [500, 200, 500, 200, 500, 500, 1000, 500, 1000, 500, 1000]);
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _buildEmergencyOverlay(incident, ctx),
      );
    }
  }

  Widget _buildEmergencyOverlay(IncidentModel incident, BuildContext ctx) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pulsing Background
          const _PulsingSirenBackground(),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Siren Icon with intense animation
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 50,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.white, size: 120),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 400.ms)
                .shake(hz: 4, rotation: 0.05)
                .shimmer(color: Colors.redAccent),
                
                const SizedBox(height: 48),
                
                Text(
                  "URGENT EMERGENCY",
                  style: AppTextStyles.heading.copyWith(
                    color: Colors.white, 
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds).scale(duration: 400.ms),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "ROOM ${incident.roomNumber}",
                    style: AppTextStyles.title.copyWith(color: Colors.red, fontWeight: FontWeight.w900),
                  ),
                ).animate().slideY(begin: 0.5),
                
                const SizedBox(height: 12),
                
                Text(
                  incident.type.toUpperCase(),
                  style: AppTextStyles.title.copyWith(color: Colors.white, letterSpacing: 2),
                ),
                
                const SizedBox(height: 64),
                
                SizedBox(
                  width: 280,
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 20,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/incident_detail/${incident.id}');
                    },
                    child: const Text(
                      "ACKNOWLEDGE NOW",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(duration: 1.seconds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startEscalationWatcher() {
    _escalationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      firestore.escalateOldIncidents();
    });
  }

  @override
  void dispose() {
    _escalationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    final connectivity = Provider.of<ConnectivityProvider>(context);

    return Scaffold(
      backgroundColor: context.tc.bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                "ResQ Command",
                style: AppTextStyles.title.copyWith(color: context.tc.textPrimary, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _buildLiveIndicator(),
          ],
        ),
        actions: [
          // ... (keep actions same) ...
          // Point 3: Offline Emergency Mode (Sync Indicator)
          if (!connectivity.isOnline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Tooltip(
                message: "Offline Mode: Incidents will sync when reconnected",
                child: Icon(Icons.cloud_off, color: AppColors.warning),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await Provider.of<AuthService>(context, listen: false)
                    .signOut();
                if (mounted) context.go('/entry');
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: FutureBuilder<StaffModel?>(
              future: firestore.getStaffProfile(
                  Provider.of<AuthService>(context, listen: false)
                          .currentUser
                          ?.uid ??
                      ''),
              builder: (context, snapshot) {
                final role = snapshot.data?.role ?? "Duty Manager";
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Provider.of<ThemeNotifier>(context).isDark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: context.tc.textPrimary,
              size: 22,
            ),
            onPressed: () =>
                Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.analytics_outlined,
                color: context.tc.isDark ? Colors.white : AppColors.primary,
                size: 22),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const AnalyticsDashboardScreen())),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<List<IncidentModel>>(
          stream: firestore.getActiveIncidents(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(child: Text("Error: ${snapshot.error}"));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final incidents = snapshot.data!;

            // Step 4 — Populating IncidentProvider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<IncidentProvider>().setIncidents(incidents);
              }
            });
            
            // Step 2 — Detect new incidents
            _handleNewIncidents(incidents);

            final isOnline = connectivity.isOnline;
            final nearby = Provider.of<NearbyService>(context, listen: false);

            if (!isOnline) {
              _initMesh(nearby);
            } else {
              _stopMesh(nearby);
            }

            return Stack(
              children: [
                Column(
                  children: [
                    ConnectivityBanner(isOnline: isOnline),
                    if (_currentIndex == 0) _buildDashboardTab(incidents),
                    if (_currentIndex == 1) _buildIncidentsTab(),
                    if (_currentIndex == 2) _buildTeamTab(),
                    if (_currentIndex == 3) const AuditLogScreen(),
                  ],
                ),
                // FIX D: In-App Incident Banner
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.fastOutSlowIn,
                    height: _isShowingBanner ? 70 : 0,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppShadows.card],
                    ),
                    child: _isShowingBanner && _currentBannerIncident != null
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() => _isShowingBanner = false);
                                context.push('/incident_detail/${_currentBannerIncident!.id}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    const Icon(Icons.emergency_rounded, color: Colors.white, size: 28)
                                        .animate(onPlay: (c) => c.repeat())
                                        .shake(),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "NEW ${_currentBannerIncident!.type.toUpperCase()} ALERT",
                                            style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                                          ),
                                          Text(
                                            "Room ${_currentBannerIncident!.roomNumber} — Respond now",
                                            style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                    const Icon(Icons.chevron_right, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          }),
      bottomNavigationBar: CoralBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  void _handleNewIncidents(List<IncidentModel> incidents) async {
    final currentStaffId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (currentStaffId == null) return;

    for (var incident in incidents) {
      if (!_seenIncidentIds.contains(incident.id)) {
        final isFresh = DateTime.now().difference(incident.createdAt).inSeconds < 30;
        
        if (isFresh && incident.status == 'received') {
          _seenIncidentIds.add(incident.id);
          
          // FIX D: Add to banner queue
          _pendingBanners.add(incident);
          _showNextBanner();

          final isClosest = await _assignmentService.isClosestStaff(incident, currentStaffId);
          if (isClosest && mounted) {
            _showVerificationOverlay(incident, currentStaffId);
          }
        } else {
           _seenIncidentIds.add(incident.id); // Mark as seen even if old
        }
      }
    }
  }

  void _showVerificationOverlay(IncidentModel incident, String currentStaffId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => VerificationOverlay(
        onConfirm: () async {
          Navigator.pop(ctx);
          
          // Get actual name from profile
          final firestore = Provider.of<FirestoreService>(context, listen: false);
          final profile = await firestore.getStaffProfile(currentStaffId);
          final currentStaffName = profile?.name ?? "Staff Member";

          await firestore.updateIncident(incident.id, {
            'verifiedBy': currentStaffId,
            'verifiedAt': FieldValue.serverTimestamp(),
            'status': 'assigned',
            'assignedResponderId': currentStaffId,
            'assignedResponderName': currentStaffName,
          });
        },
        onCancel: () async {
          Navigator.pop(ctx);
          await Provider.of<FirestoreService>(context, listen: false).updateIncident(incident.id, {
            'isFalseAlarm': true,
            'status': 'resolved',
            'falseAlarmReason': 'Staff marked false alarm at verification',
            'resolvedAt': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }

  Widget _buildDashboardTab(List<IncidentModel> incidents) {
    return Expanded(
      child: Column(
        children: [
          // Map placeholder with venue floor plan
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.tc.isDark
                  ? const Color(0xFF1A1A28)
                  : Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: context.tc.border)),
            ),
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _defaultPos,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  markers: _buildGoogleMarkers(incidents),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.tc.cardColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: context.tc.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text("${incidents.length} Active Incidents",
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Mesh Peer Alerts Section
          Consumer<NearbyService>(
            builder: (context, nearby, _) {
              if (nearby.receivedIncidents.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: const Border(bottom: BorderSide(color: Colors.red, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hub_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "P2P MESH ALERTS (${nearby.receivedIncidents.length})",
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.red, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => nearby.clearReceivedIncidents(),
                          child: const Text("CLEAR", style: TextStyle(color: Colors.red, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...nearby.receivedIncidents.map((inc) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Text("🚨 ROOM ${inc['roomNumber']}", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              inc['description'] ?? 'No description',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white54),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                _buildStatCard("Critical", incidents.where((i) => i.severity >= 4).length, Colors.redAccent),
                const SizedBox(width: 12),
                _buildStatCard("Medium", incidents.where((i) => i.severity == 3).length, Colors.orangeAccent),
                const SizedBox(width: 12),
                _buildStatCard("Low", incidents.where((i) => i.severity <= 2).length, Colors.greenAccent),
              ],
            ),
          ),
          // Incident list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 80),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                final minutesElapsed =
                    DateTime.now().difference(incident.createdAt).inMinutes;
                return IncidentCard(
                  id: incident.id,
                  type: incident.type,
                  roomNumber: incident.roomNumber,
                  aiSummary: incident.aiSummary ?? '',
                  description: incident.description,
                  severity: incident.severity,
                  status: incident.status,
                  assignedResponder: incident.assignedResponderId,
                  minutesElapsed: minutesElapsed,
                  triageStartedAt: incident.triageStartedAt,
                  triageCompletedAt: incident.triageCompletedAt,
                  onAutoAssign: () => _assignmentService.autoAssignStaff(
                      incident, 0, 0), // Mock coordinates
                )
                    .animate()
                    .fadeIn(delay: (index * 50).ms)
                    .slideX(begin: 0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildGoogleMarkers(List<IncidentModel> incidents) {
    final markers = incidents.map((incident) {
      // Use real lat/lng or deterministic fallback for the hackathon demo
      final lat =
          incident.lat ?? (28.6139 + (incident.id.hashCode % 100) / 5000);
      final lng = incident.lng ??
          (77.2090 + ((incident.id.hashCode ~/ 100) % 100) / 5000);

      double hue = BitmapDescriptor.hueRed;
      if (incident.severity == 3) hue = BitmapDescriptor.hueOrange;
      if (incident.severity <= 2) hue = BitmapDescriptor.hueGreen;

      return Marker(
        markerId: MarkerId(incident.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: "Room ${incident.roomNumber}",
          snippet: incident.type.toUpperCase(),
          onTap: () => context.push('/incident_detail?id=${incident.id}'),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      );
    }).toSet();

    // Trigger auto-zoom if markers changed
    if (markers.length != _markers.length) {
      _markers = markers;
      _autoZoom();
    }

    return markers;
  }

  void _autoZoom() async {
    if (_markers.isEmpty) return;
    final GoogleMapController controller = await _mapController.future;

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var m in _markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.002, minLng - 0.002),
          northeast: LatLng(maxLat + 0.002, maxLng + 0.002),
        ),
        50,
      ),
    );
  }

  Widget _buildStatChip(String label, int count) {
    bool isHovered = false;
    return Expanded(
      child: StatefulBuilder(
        builder: (context, setState) => MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedScale(
            scale: isHovered ? 1.05 : 1.0,
            duration: 200.ms,
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: context.tc.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : context.tc.cardShadow,
                border: Border.all(
                    color: isHovered
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent),
              ),
              child: Column(
                children: [
                  Text("$count",
                      style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.tc.textPrimary)),
                  Text(label,
                      style: AppTextStyles.caption
                          .copyWith(color: context.tc.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentsTab() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    return Expanded(
      child: StreamBuilder<List<IncidentModel>>(
          stream: firestore.streamAllIncidents(),
          
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final allIncidents = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allIncidents.length,
              itemBuilder: (context, index) {
                final i = allIncidents[index];
                return Card(
                  color: context.tc.cardColor,
                  margin: const EdgeInsets.only(bottom: 7),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.getSeverityColor(i.severity),
                      child: Text("${i.severity}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text("Room ${i.roomNumber} — ${i.type}",
                        style: TextStyle(color: context.tc.textPrimary)),
                    subtitle: Text(
                        i.aiSummary != null && i.aiSummary!.contains('failed')
                            ? i.description
                            : (i.aiSummary ?? i.description),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.tc.textSecondary)),
                    trailing: Text(i.status.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                            color: i.status == 'resolved'
                                ? AppColors.success
                                : AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          }),
    );
  }

  Widget _buildTeamTab() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Expanded(
      child: StreamBuilder<List<StaffModel>>(
        stream: firestore.streamStaff(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final team = snapshot.data ?? [];
          if (team.isEmpty) {
            return Center(
                child: Text("No staff profiles found",
                    style: TextStyle(color: context.tc.textSecondary)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: team.length,
            itemBuilder: (context, index) {
              final member = team[index];
              final isOnline = member.status.toLowerCase() != 'offline';

              return Card(
                color: context.tc.cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOnline ? AppColors.success : Colors.grey,
                    child: Text(member.name.substring(0, 1),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(member.name,
                      style: TextStyle(color: context.tc.textPrimary)),
                  subtitle: Text(member.role,
                      style: TextStyle(color: context.tc.textSecondary)),
                  trailing: Text(member.status.toUpperCase(),
                      style: TextStyle(
                          color: isOnline ? AppColors.success : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _initMesh(NearbyService nearby) async {
    if (_isNearbyActive) return;
    _isNearbyActive = true;

    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final profile = await firestore.getStaffProfile(auth.currentUser?.uid ?? '');
    final name = profile?.name ?? "Staff Member";

    nearby.onSOSReceived = (incidentData) {
      // In a real app, we would store this locally and sync when back online
      // For the demo, we show a notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("MESH ALERT: Room ${incidentData['roomNumber']} SOS!"),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: "VIEW",
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    };

    nearby.startAdvertising(name);
    nearby.startDiscovery();
  }

  void _stopMesh(NearbyService nearby) {
    if (!_isNearbyActive) return;
    _isNearbyActive = false;
    nearby.stopAll();
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: context.tc.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text("$count",
                style: AppTextStyles.title.copyWith(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: context.tc.textSecondary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    final now = DateTime.now();
    final isStale = _lastPingTime == null || now.difference(_lastPingTime!).inSeconds > 10;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isStale)
          const Icon(Icons.circle, color: Colors.amber, size: 8)
        else
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 800.ms, curve: Curves.easeInOut).fadeOut(duration: 800.ms),
        const SizedBox(width: 4),
        Text(
          isStale ? "SYNCING..." : "LIVE",
          style: TextStyle(
            color: isStale ? Colors.amber : Colors.greenAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PulsingSirenBackground extends StatefulWidget {
  const _PulsingSirenBackground();

  @override
  State<_PulsingSirenBackground> createState() => _PulsingSirenBackgroundState();
}

class _PulsingSirenBackgroundState extends State<_PulsingSirenBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.red.withValues(alpha: 0.2 + (0.6 * _controller.value)),
                Colors.black,
              ],
              radius: 1.2,
            ),
          ),
        );
      },
    );
  }
}
