import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/theme_colors.dart';
import '../../../core/models/incident_model.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'video_call_screen.dart';
import 'public_handoff_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/storage_service.dart';
import 'package:intl/intl.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String id;

  const IncidentDetailScreen({super.key, required this.id});

  @override
  _IncidentDetailScreenState createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  StaffModel? _selectedStaff;
  String _status = 'received';
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<IncidentModel>(
      stream: firestore.streamIncident(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildErrorScreen("BRIEF NOT FOUND", "The incident ID may be invalid or expired.");
        }
        final incident = snapshot.data!;
        _status = incident.status;

        return FutureBuilder<StaffModel?>(
          future: auth.currentUser?.uid != null 
              ? firestore.getStaffProfile(auth.currentUser!.uid) 
              : Future.value(null),
          builder: (context, staffSnapshot) {
            // Handle error gracefully if staff profile not found
            if (staffSnapshot.hasError) {
               return _buildErrorScreen("ACCESS ERROR", "Your staff profile could not be verified.");
            }
            final currentStaff = staffSnapshot.data;
            final role = currentStaff?.role.toLowerCase() ?? '';
            final isManager = role == 'manager' || role == 'admin';

            return Scaffold(
              backgroundColor: context.tc.bgColor,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text("Incident #${widget.id.substring(0, 8)}...", 
                    style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 16)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                    tooltip: "Live Video Feed",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoCallScreen(
                            incidentId: widget.id,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    onPressed: () async {
                      final pdfFile = await PdfService().generateIncidentReport(incident);
                      await Share.shareXFiles([XFile(pdfFile.path)], text: 'ResQ Incident Report - Room ${incident.roomNumber}');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
                    tooltip: "Copy Clean Incident ID",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Raw Incident ID copied"),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.black87,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                    onPressed: () {
                      Share.share("RESQ BRIEF: Room ${incident.roomNumber}\nID: ${widget.id}");
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Hero(
                      tag: 'incident_${widget.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: _buildHeroSection(incident),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAssignSection(incident, currentStaff, isManager),
                          const SizedBox(height: 32),
                          _buildStatusTimeline(incident),
                          const SizedBox(height: 32),
                          _buildActionButtons(incident, currentStaff, isManager),
                          const SizedBox(height: 32),
                          _buildMediaSection(incident),
                          const SizedBox(height: 32),
                          _buildGenerateBrief(),
                          if (incident.status == 'resolved' || _status == 'resolved') ...[
                            const SizedBox(height: 32),
                            _buildPostIncidentReport(incident),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildAssignSection(IncidentModel incident, StaffModel? currentStaff, bool isManager) {
    if (incident.assignedResponderId != null && incident.assignedResponderId!.isNotEmpty) {
      return _buildAssignedState(incident, isManager);
    }

    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Assign Response Team", style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
        const SizedBox(height: 16),
        StreamBuilder<List<StaffModel>>(
          stream: firestore.streamStaff(),
          builder: (context, snapshot) {
            final availableStaff = (snapshot.data ?? [])
                .where((s) => s.status == 'available')
                .toList();
            
            // Sort: Same floor first
            availableStaff.sort((a, b) {
              final aSameFloor = a.floor == incident.floor;
              final bSameFloor = b.floor == incident.floor;
              if (aSameFloor && !bSameFloor) return -1;
              if (!aSameFloor && bSameFloor) return 1;
              return 0;
            });

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.tc.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _selectedStaff != null ? AppColors.primary : AppColors.primaryLight,
                      child: Text(
                        _selectedStaff?.name.substring(0, 1).toUpperCase() ?? "?",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      _selectedStaff?.name ?? "Select Available Staff",
                      style: TextStyle(color: context.tc.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    subtitle: _selectedStaff != null 
                        ? Text("${_selectedStaff!.role} • ${_selectedStaff!.floor == incident.floor ? 'Same Floor' : 'Floor ${_selectedStaff!.floor}'}")
                        : const Text("Only showing available responders"),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () => _showResponderPicker(availableStaff, incident),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _assignToMe(incident, currentStaff),
                        icon: const Icon(Icons.person_pin_circle_outlined, color: AppColors.primary),
                        label: const Text("Assign to Me"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedStaff == null ? null : () => _confirmAssignment(incident, _selectedStaff!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: const Text("Confirm Assign"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        ),
      ],
    );
  }

  Widget _buildAssignedState(IncidentModel incident, bool isManager) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.success,
                child: Icon(Icons.check, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("✓ Assigned to ${incident.assignedResponderName}", 
                      style: AppTextStyles.body.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                    Text("Response Unit Locked", style: AppTextStyles.caption.copyWith(color: context.tc.textSecondary)),
                  ],
                ),
              ),
              if (isManager)
                TextButton(
                  onPressed: () => _reassignIncident(incident),
                  child: const Text("Reassign", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _assignToMe(IncidentModel incident, StaffModel? currentStaff) async {
    if (currentStaff == null) return;
    
    final firestore = FirebaseFirestore.instance;
    final incidentRef = firestore.collection('incidents').doc(incident.id);
    
    try {
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(incidentRef);
        if (!snapshot.exists) return;
        
        final data = snapshot.data()!;
        if (data['assignedResponderId'] != null && (data['assignedResponderId'] as String).isNotEmpty) {
          throw Exception("Already assigned to someone else");
        }
        
        transaction.update(incidentRef, {
          'assignedResponderId': currentStaff.id,
          'assignedResponderName': currentStaff.name,
          'status': 'assigned',
          'assignedAt': FieldValue.serverTimestamp(),
        });
        
        // Also update staff status
        transaction.update(firestore.collection('staff').doc(currentStaff.id), {
          'status': 'enRoute',
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Assigned to you successfully"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _confirmAssignment(IncidentModel incident, StaffModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Assignment"),
        content: Text("Assign ${staff.name} to this incident?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final firestore = Provider.of<FirestoreService>(context, listen: false);
              
              await firestore.updateIncident(incident.id, {
                'assignedResponderId': staff.id,
                'assignedResponderName': staff.name,
                'status': 'assigned',
                'assignedAt': FieldValue.serverTimestamp(),
              });
              
              await firestore.updateIncident(incident.id, {'status': 'assigned'});
              // Note: Ideally updating staff status too
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${staff.name} assigned successfully"), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<void> _reassignIncident(IncidentModel incident) async {
    final prevStaffId = incident.assignedResponderId;

    if (prevStaffId != null && prevStaffId.isNotEmpty) {
      await FirestoreService().updateStaffStatus(prevStaffId, 'available');
    }

    await FirestoreService().updateIncident(incident.id, {
      'assignedResponderId': null,
      'assignedResponderName': null,
      'status': 'received',
    });

    setState(() {
      _selectedStaff = null;
    });
  }

  void _showResponderPicker(List<StaffModel> staff, IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tc.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Responder", style: AppTextStyles.title),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: staff.length,
                itemBuilder: (context, index) {
                  final s = staff[index];
                  final isSameFloor = s.floor == incident.floor;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Text(s.name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${s.role} • Floor ${s.floor}"),
                      trailing: isSameFloor 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Text("SAME FLOOR", style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedStaff = s);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(IncidentModel incident, StaffModel? currentStaff, bool isManager) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton("En Route", incident.status == 'en_route', () {
                firestore.updateIncident(incident.id, {'status': 'en_route'});
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton("On Scene", incident.status == 'on_scene', () {
                firestore.updateIncident(incident.id, {'status': 'on_scene'});
              }),
            ),
          ],
        ),
        if (isManager) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (incident.status == 'resolved') 
                  ? null 
                  : () => _showResolutionChecklist(incident, currentStaff),
              style: ElevatedButton.styleFrom(
                backgroundColor: (incident.status == 'resolved') ? Colors.grey : AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                  (incident.status == 'resolved') ? "INCIDENT RESOLVED" : "MARK RESOLVED", 
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ],
    );
  }

  void _showResolutionChecklist(IncidentModel incident, StaffModel? currentStaff) {
    bool _guestSafe = false;
    bool _areaClear = false;
    bool _servicesNotified = false;
    final _notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Confirm Resolution',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: _guestSafe,
                onChanged: (v) => setState(() => _guestSafe = v!),
                title: const Text('Guest has been confirmed safe'),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _areaClear,
                onChanged: (v) => setState(() => _areaClear = v!),
                title: const Text('Affected area is cleared or contained'),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _servicesNotified,
                onChanged: (v) => setState(() => _servicesNotified = v!),
                title: const Text('All required services have been notified'),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Resolution notes (optional)',
                  hintText: 'Describe how the incident was resolved',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (_guestSafe && _areaClear && _servicesNotified)
                  ? () async {
                      Navigator.pop(ctx);
                      await FirestoreService().updateIncident(incident.id, {
                        'status': 'resolved',
                        'resolvedAt': FieldValue.serverTimestamp(),
                        'resolvedBy': currentStaff?.id,
                        'resolvedByName': currentStaff?.name,
                        'resolvedByRole': currentStaff?.role,
                        'resolutionNotes': _notesController.text,
                        'resolutionChecklist': {
                          'guestSafe': true,
                          'areaClear': true,
                          'servicesNotified': true,
                        },
                      });
                      FirestoreService().generatePostIncidentReport(incident.id);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Confirm Resolution',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? AppGradients.primary : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(IncidentModel incident) {
    final severityColor = AppColors.getSeverityColor(incident.severity);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              "ROOM ${incident.roomNumber}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            incident.type.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeroStat("Severity", incident.severity.toString(), severityColor),
              const SizedBox(width: 24),
              _buildHeroStat("Status", incident.status.toUpperCase(), Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusTimeline(IncidentModel incident) {
    int currentStep = 0;
    switch (incident.status) {
      case 'received': currentStep = 0; break;
      case 'assigned': currentStep = 1; break;
      case 'en_route':  currentStep = 2; break;
      case 'on_scene':  currentStep = 3; break;
      case 'resolved': currentStep = 4; break;
      default: currentStep = 0;
    }

    final steps = [
      {'label': 'Received', 'time': incident.createdAt},
      {'label': 'Assigned', 'time': incident.assignedAt},
      {'label': 'En Route', 'time': null},
      {'label': 'On Scene', 'time': null},
      {'label': 'Resolved', 'time': incident.resolvedAt},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Response Timeline", style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
        const SizedBox(height: 16),
        ...List.generate(steps.length, (i) {
          final isDone = i <= currentStep;
          final isLast = i == steps.length - 1;
          final step = steps[i];
          
          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success : context.tc.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDone ? AppColors.success : context.tc.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label'] as String,
                          style: TextStyle(
                            color: isDone ? context.tc.textPrimary : context.tc.textSecondary,
                            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (step['time'] != null)
                          Text(
                            DateFormat('HH:mm:ss').format(step['time'] as DateTime),
                            style: TextStyle(color: context.tc.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _pickAndUploadImage(IncidentModel incident) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    
    if (image == null) return;

    setState(() => _isUploading = true);
    
    try {
      final storage = StorageService();
      final url = await storage.uploadIncidentImage(incident.id, image.path);
      
      if (url != null) {
        final firestore = Provider.of<FirestoreService>(context, listen: false);
        await firestore.updateIncident(incident.id, {
          'mediaUrls': FieldValue.arrayUnion([url])
        });
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildGenerateBrief() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: const [AppShadows.soft],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("First Responder Brief", style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: 8),
          Text("Generate a concise summary for external services.", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share, size: 18),
              label: Text("Generate & Share", style: AppTextStyles.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(IncidentModel incident) {
    final mediaUrls = incident.mediaUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Media", style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: _isUploading ? null : () => _pickAndUploadImage(incident),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.tc.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.tc.border, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: _isUploading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.add_a_photo, color: context.tc.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ...mediaUrls.map((url) => Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () async {
                          final firestore = Provider.of<FirestoreService>(context, listen: false);
                          await firestore.removeIncidentMedia(incident.id, url);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostIncidentReport(IncidentModel incident) {
    final report = incident.postIncidentReport ?? "Awaiting analysis...";
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), // Deep dark professional theme
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.article_rounded, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 10),
                Text(
                  "OFFICIAL POST-INCIDENT REPORT",
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    report,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                      fontSize: 15,
                      fontStyle: incident.postIncidentReport == null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReport(incident),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("EXPORT AS PDF"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareReport(IncidentModel incident) async {
     final pdfFile = await PdfService().generateIncidentReport(incident);
     await Share.shareXFiles([XFile(pdfFile.path)], text: 'Official Incident Report - Room ${incident.roomNumber}');
  }

  Widget _buildErrorScreen(String title, String message) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.white24, size: 80),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
