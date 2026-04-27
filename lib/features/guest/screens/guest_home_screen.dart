import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/services/firestore_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/theme_colors.dart';
import '../../../core/services/theme_notifier.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/nfc_service.dart';
import '../../../core/services/nearby_service.dart';
import '../widgets/sos_pulse_button.dart';
import '../../staff/widgets/connectivity_banner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/incident_model.dart';
import '../../../core/models/staff_model.dart';

class GuestHomeScreen extends StatefulWidget {
  final String roomNumber;
  const GuestHomeScreen({super.key, required this.roomNumber});

  @override
  _GuestHomeScreenState createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  StreamSubscription? _accelerometerSub;
  final List<double> _accelerations = [];
  DateTime _lastShakeTime = DateTime.now();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _currentSSID;
  final NfcService _nfcService = NfcService();
  bool _isNearbyActive = false;

  @override
  void initState() {
    super.initState();
    _initShakeDetection();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
    _checkWiFi();
    _initNfc();
  }

  void _initNfc() {
    _nfcService.startSession(onTagRead: (tagData) {
      if (mounted) _triggerShakeSos();
    });
  }

  void _initMesh(NearbyService nearby) {
    if (_isNearbyActive) return;
    _isNearbyActive = true;
    nearby.startAdvertising(widget.roomNumber);
    nearby.startDiscovery();
  }

  void _stopMesh(NearbyService nearby) {
    if (!_isNearbyActive) return;
    _isNearbyActive = false;
    nearby.stopAll();
  }

  Future<void> _checkWiFi() async {
    final connectivity = Provider.of<ConnectivityService>(context, listen: false);
    final ssid = await connectivity.getWifiSSID();
    if (mounted) {
      setState(() => _currentSSID = ssid);
    }
  }

  void _initShakeDetection() {
    _accelerometerSub = userAccelerometerEventStream().listen((event) {
      double acceleration =
          event.x * event.x + event.y * event.y + event.z * event.z;
      if (acceleration > 400) {
        DateTime now = DateTime.now();
        if (now.difference(_lastShakeTime) >
            const Duration(milliseconds: 500)) {
          _accelerations.add(acceleration);
          _lastShakeTime = now;
          _accelerations.removeWhere((a) =>
              now.difference(_lastShakeTime) > const Duration(seconds: 2));
          if (_accelerations.length >= 3) {
            _accelerations.clear();
            _triggerShakeSos();
          }
        }
      }
    });
  }

  Future<void> _triggerShakeSos() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) Vibration.vibrate();
    if (mounted) context.push('/countdown?room=${widget.roomNumber}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _accelerometerSub?.cancel();
    _fadeController.dispose();
    _nfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = Provider.of<ConnectivityService>(context).isOnline;
    final nearby = Provider.of<NearbyService>(context, listen: false);

    if (!isOnline) {
      _initMesh(nearby);
    } else {
      _stopMesh(nearby);
    }

    return Scaffold(
      backgroundColor: context.tc.bgColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConnectivityBanner(isOnline: isOnline),
              _buildHeroArea()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              _buildServicesGrid()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 24),
              _buildSafetyTips()
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Icon(Icons.shield, color: AppColors.primary),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text("Room ${widget.roomNumber}",
                style: AppTextStyles.caption.copyWith(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
            if (_currentSSID == "Hotel_Guest_WiFi") ...[
              const SizedBox(width: 8),
              const Icon(Icons.wifi_lock, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text("G",
                style: AppTextStyles.button
                    .copyWith(color: const Color(0xFFFF4D67))),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              context.go('/entry');
            } else if (value == 'theme') {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            }
          },
          itemBuilder: (context) {
            final isDark =
                Provider.of<ThemeNotifier>(context, listen: false).isDark;
            return [
              PopupMenuItem(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(isDark ? 'Light Mode' : 'Dark Mode'),
                    ],
                  )),
              const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  )),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildHeroArea() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFF4D67), const Color(0xFFFF8599)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D67).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text("CRITICAL SOS",
                  style: AppTextStyles.title.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            ],
          ),
          const SizedBox(height: 24),
          SosPulseButton(roomNumber: widget.roomNumber),
          const SizedBox(height: 24),
          Text("HELP DISPATCH TRIGGER",
              style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickChip('🔥', 'Fire', '/sos_trigger?type=fire&room=${widget.roomNumber}'),
              _buildQuickChip('🏥', 'Medical', '/sos_trigger?type=medical&room=${widget.roomNumber}'),
              _buildQuickChip('🔒', 'Security', '/sos_trigger?type=security&room=${widget.roomNumber}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String emoji, String label, String route) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedScale(
          scale: isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: InkWell(
            onTap: () => context.push(route),
            borderRadius: BorderRadius.circular(100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10)
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Text(emoji),
                  const SizedBox(width: 4),
                  Text(label,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Services",
              style:
                  AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
          const SizedBox(height: 16),
          StreamBuilder<IncidentModel?>(
            stream: Provider.of<FirestoreService>(context, listen: false).getGuestActiveIncident(widget.roomNumber),
            builder: (context, snapshot) {
              final activeIncident = snapshot.data;
              final hasAlert = activeIncident != null;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildServiceCard(
                      'Care Team', "View who's on duty", Icons.people_alt_rounded,
                      () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: context.tc.cardColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      builder: (ctx) => _buildCareTeamSheet(),
                    );
                  }),
                  _buildServiceCard(
                      'My Status', 
                      hasAlert ? 'Help is on the way' : 'No active alerts', 
                      hasAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      () {
                    if (hasAlert) {
                      context.push('/status_tracking?type=${activeIncident.type}&id=${activeIncident.id}&room=${widget.roomNumber}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No active alert. Trigger an SOS first.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildCareTeamSheet() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tc.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Care Team On Duty",
              style: AppTextStyles.heading
                  .copyWith(color: context.tc.textPrimary)),
          const SizedBox(height: 16),
          StreamBuilder<List<StaffModel>>(
            stream: firestore.getOnDutyStaff(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final team = snapshot.data ?? [];
              if (team.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text("No staff currently on duty",
                        style: TextStyle(color: context.tc.textSecondary)),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: team
                    .map((m) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.success,
                            child: Text(m.name.substring(0, 1),
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(m.name,
                              style: TextStyle(color: context.tc.textPrimary)),
                          subtitle: Text(m.role,
                              style:
                                  TextStyle(color: context.tc.textSecondary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(m.status.toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              if (m.phone?.isNotEmpty == true) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                                  onPressed: () => launchUrl(Uri.parse('tel:${m.phone}')),
                                ),
                              ],
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: context.tc.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                border: Border.all(
                    color: isHovered
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.primary.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.primary, size: 28),
                  const Spacer(),
                  Text(title,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.tc.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 10, color: context.tc.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text("Safety Tips",
              style:
                  AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: PageView(
            controller: _pageController,
            children: [
              _buildTipCard("Know your exits", Icons.map, onTap: () => _showMapDialog()),
              _buildTipCard("Assembly point: Hotel Lobby", Icons.location_on, onTap: () => _showAssemblyPoint()),
              _buildTipCard("Emergency Contacts", Icons.phone_in_talk, onTap: () => _showEmergencyContacts()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: const ExpandingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.primaryLight,
              dotHeight: 8,
              dotWidth: 8,
            ),
          ),
        ),
      ],
    );
  }

  void _showEmergencyContacts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tc.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Emergency Services", style: AppTextStyles.heading.copyWith(color: context.tc.textPrimary)),
            const SizedBox(height: 8),
            Text("Direct links to local emergency responders", style: TextStyle(color: context.tc.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            _buildEmergencyContactItem("Ambulance", "102", Icons.medical_services, Colors.redAccent),
            _buildEmergencyContactItem("Police", "100", Icons.local_police, Colors.blueAccent),
            _buildEmergencyContactItem("Fire Brigade", "101", Icons.fire_truck, Colors.orangeAccent),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactItem(String label, String number, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: TextStyle(color: context.tc.textPrimary, fontWeight: FontWeight.bold)),
      subtitle: Text(number, style: TextStyle(color: context.tc.textSecondary)),
      trailing: ElevatedButton.icon(
        onPressed: () => launchUrl(Uri.parse('tel:$number')),
        icon: const Icon(Icons.call, size: 16, color: Colors.white),
        label: const Text("CALL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
    );
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Emergency Floor Plan", style: AppTextStyles.title.copyWith(color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  child: Image.asset(
                    'assets/images/hotel_floor_map.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, color: Colors.white54, size: 48),
                            SizedBox(height: 16),
                            Text("Floor plan coming soon...", style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssemblyPoint() {
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Proceed to the main Hotel Lobby assembly point."),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTipCard(String text, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.tc.cardShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Text(text,
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold))),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }
}
