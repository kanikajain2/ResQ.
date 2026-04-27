import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/theme_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/incident_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _selectedType = 'All';
  String _selectedTimeRange = 'All Time';
  int? _expandedIndex;

  final List<String> _types = ['All', 'Fire', 'Medical', 'Security', 'Other'];
  final List<String> _timeRanges = ['Today', 'This Week', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);

    return Expanded(
      child: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<IncidentModel>>(
              stream: firestore.streamAllIncidents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const LoadingShimmer();
                }

                final allResolved = snapshot.data!
                    .where((i) => i.status == 'resolved')
                    .toList();
                
                // Apply resolution sorting (descending)
                allResolved.sort((a, b) {
                  final bTime = b.resolvedAt ?? b.createdAt;
                  final aTime = a.resolvedAt ?? a.createdAt;
                  return bTime.compareTo(aTime);
                });

                final filteredIncidents = _filterIncidents(allResolved);

                if (filteredIncidents.isEmpty) {
                  return const EmptyStateWidget(
                    title: "No incidents found",
                    subtitle: "No resolved incidents yet for the selected filters",
                    icon: Icons.history,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredIncidents.length,
                  itemBuilder: (context, index) {
                    return _buildAuditCard(filteredIncidents[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.tc.cardColor,
        border: Border(bottom: BorderSide(color: context.tc.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _types.map((type) => _buildFilterChip(type, _selectedType == type, () {
                setState(() => _selectedType = type);
              })).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _timeRanges.map((range) => _buildFilterChip(range, _selectedTimeRange == range, () {
                setState(() => _selectedTimeRange = range);
              })).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<IncidentModel> _filterIncidents(List<IncidentModel> incidents) {
    return incidents.where((i) {
      // Type Filter
      if (_selectedType != 'All' && i.type.toLowerCase() != _selectedType.toLowerCase()) {
        if (_selectedType == 'Other' && ['fire', 'medical', 'security'].contains(i.type.toLowerCase())) {
          return false;
        } else if (_selectedType != 'Other') {
          return false;
        }
      }

      // Time Filter
      final now = DateTime.now();
      final date = i.resolvedAt ?? i.createdAt;
      if (_selectedTimeRange == 'Today') {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } else if (_selectedTimeRange == 'This Week') {
        return now.difference(date).inDays <= 7;
      }

      return true;
    }).toList();
  }

  Widget _buildAuditCard(IncidentModel incident, int index) {
    final isExpanded = _expandedIndex == index;
    final dateStr = DateFormat("dd MMM yyyy · HH:mm").format(incident.resolvedAt ?? incident.createdAt);
    final duration = incident.resolvedAt != null 
        ? incident.resolvedAt!.difference(incident.createdAt).inMinutes 
        : 0;
    
    final typeIcon = _getTypeIcon(incident.type);
    final typeColor = AppColors.getSeverityColor(incident.severity);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.tc.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: context.tc.cardShadow,
        border: Border.all(color: isExpanded ? typeColor.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: typeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(typeIcon, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Room ${incident.roomNumber}", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: context.tc.textPrimary, fontSize: 16)),
                                Text(dateStr, style: AppTextStyles.caption.copyWith(color: context.tc.textSecondary)),
                              ],
                            ),
                          ),
                          Text("$duration min", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: typeColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(incident.assignedResponderName ?? "Unknown Responder", style: AppTextStyles.caption.copyWith(color: Colors.grey)),
                          const Spacer(),
                          if (incident.isFalseAlarm ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                              child: Text("FALSE ALARM", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          IconButton(
                            onPressed: () => setState(() => _expandedIndex = isExpanded ? null : index),
                            icon: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 32),
                        _buildDetailRow("AI SUMMARY", incident.aiSummary ?? "No summary available"),
                        const SizedBox(height: 16),
                        _buildDetailRow("FINAL REPORT", incident.postIncidentReport ?? "No report submitted"),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _shareReport(incident),
                            icon: const Icon(Icons.ios_share_rounded, size: 18),
                            label: const Text("Share Detailed Report"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body.copyWith(fontSize: 13, color: context.tc.textPrimary)),
      ],
    );
  }

  String _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return '🔥';
      case 'medical': return '🏥';
      case 'security': return '🔒';
      default: return '⚠️';
    }
  }

  void _shareReport(IncidentModel incident) {
    final report = """
ResQ Incident Report
Room: ${incident.roomNumber}
Type: ${incident.type.toUpperCase()}
Status: Resolved
Resolution Time: ${incident.resolvedAt?.difference(incident.createdAt).inMinutes} min
Responder: ${incident.assignedResponderName}
AI Summary: ${incident.aiSummary}
Post-Report: ${incident.postIncidentReport}
""";
    Share.share(report);
  }
}
