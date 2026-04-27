import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/theme_colors.dart';
import '../../../core/services/theme_notifier.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/incident_model.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: context.tc.bgColor,
      appBar: AppBar(
        title: Text("Safety Insights", style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
      ),
      body: StreamBuilder<List<IncidentModel>>(
        stream: firestore.streamAllIncidents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final incidents = snapshot.data ?? [];
          if (incidents.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(context, incidents),
                const SizedBox(height: 32),
                Text("Incident Distribution", style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
                const SizedBox(height: 16),
                _buildIncidentTypeChart(incidents, context),
                const SizedBox(height: 32),
                Text("Severity Breakdown", style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
                const SizedBox(height: 16),
                _buildSeverityChart(incidents, context),
                const SizedBox(height: 32),
                _buildRoomHeatmap(incidents, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: context.tc.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("No incident data available yet", style: AppTextStyles.body.copyWith(color: context.tc.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, List<IncidentModel> incidents) {
    final total = incidents.length;
    final resolved = incidents.where((i) => i.status == 'resolved').length;
    final avgSeverity = incidents.map((i) => i.severity).reduce((a, b) => a + b) / total;

    return Row(
      children: [
        Expanded(child: _buildStatCard(context, "Total Alerts", "$total", Icons.notifications_active, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, "Resolved", "$resolved", Icons.check_circle, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, "Avg Severity", avgSeverity.toStringAsFixed(1), Icons.warning, AppColors.warning)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tc.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.heading.copyWith(color: context.tc.textPrimary)),
          Text(title, style: AppTextStyles.caption.copyWith(color: context.tc.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildIncidentTypeChart(List<IncidentModel> incidents, BuildContext context) {
    final types = <String, int>{};
    for (var i in incidents) {
      types[i.type] = (types[i.type] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.tc.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 30,
                sections: types.entries.map((e) {
                  final color = _getTypeColor(e.key);
                  return PieChartSectionData(
                    color: color,
                    value: e.value.toDouble(),
                    title: "${e.value}",
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: types.keys.map((type) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: _getTypeColor(type), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(type.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.tc.textPrimary, fontSize: 10)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChart(List<IncidentModel> incidents, BuildContext context) {
    final severityCounts = List.generate(5, (index) => 0);
    for (var i in incidents) {
      if (i.severity >= 1 && i.severity <= 5) {
        severityCounts[i.severity - 1]++;
      }
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.tc.cardColor, borderRadius: BorderRadius.circular(20)),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text("S${value.toInt() + 1}", style: TextStyle(fontSize: 10, color: context.tc.textSecondary)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: severityCounts.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: AppColors.getSeverityColor(e.key + 1),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoomHeatmap(List<IncidentModel> incidents, BuildContext context) {
    final rooms = <String, int>{};
    for (var i in incidents) {
      rooms[i.roomNumber] = (rooms[i.roomNumber] ?? 0) + 1;
    }
    final sortedRooms = rooms.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Active Areas", style: AppTextStyles.title.copyWith(color: context.tc.textPrimary)),
        const SizedBox(height: 16),
        ...sortedRooms.take(5).map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: context.tc.cardColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.meeting_room, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text("Room ${e.key}", style: AppTextStyles.body.copyWith(color: context.tc.textPrimary)),
              const Spacer(),
              Text("${e.value} alerts", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: context.tc.textSecondary)),
            ],
          ),
        )),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'fire': return AppColors.danger;
      case 'medical': return AppColors.success;
      case 'security': return AppColors.primary;
      case 'harassment': return AppColors.warning;
      default: return Colors.grey;
    }
  }
}
