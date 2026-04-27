import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/staff_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class TeamStatusScreen extends StatelessWidget {
  const TeamStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Team Status", style: AppTextStyles.title),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<List<StaffModel>>(
        stream: firestore.streamStaff(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmer();
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final staff = snapshot.data ?? [];
          if (staff.isEmpty) {
            return const EmptyStateWidget(
              title: "No Team Members",
              subtitle: "No staff records found in the system.",
              icon: Icons.people_outline,
            );
          }

          // Sort staff: available -> on_scene -> others
          final sortedStaff = List<StaffModel>.from(staff);
          sortedStaff.sort((a, b) {
            int getPriority(String status) {
              if (status == 'available') return 0;
              if (status == 'on_scene') return 1;
              if (status == 'en_route') return 2;
              return 3; // offline or others
            }
            return getPriority(a.status).compareTo(getPriority(b.status));
          });

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: sortedStaff.length,
            itemBuilder: (context, index) {
              final member = sortedStaff[index];
              return _buildStaffCard(context, member);
            },
          );
        },
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, StaffModel member) {
    final initials = member.name.isNotEmpty 
        ? member.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "??";

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: member.name));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Copied ${member.name} to clipboard"), behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [AppShadows.soft],
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                initials, 
                style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 12),
            Text(
              member.name, 
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                member.role.toUpperCase(), 
                style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)
              ),
            ),
            const Spacer(),
            _buildStatusPill(member.status),
            const SizedBox(height: 8),
            Text(
              _formatLastSeen(member.lastSeen),
              style: AppTextStyles.caption.copyWith(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    String label;

    switch (status) {
      case 'available':
        color = AppColors.success;
        label = "Available";
        break;
      case 'on_scene':
        color = AppColors.primary;
        label = "On Scene";
        break;
      case 'en_route':
        color = Colors.amber;
        label = "En Route";
        break;
      default:
        color = Colors.grey;
        label = "Unavailable";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return "Never seen";
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return "Last seen just now";
    if (diff.inHours < 1) return "Last seen ${diff.inMinutes}m ago";
    if (diff.inDays < 1) return "Last seen ${diff.inHours}h ago";
    return "Last seen ${diff.inDays}d ago";
  }
}
