import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/theme_colors.dart';

class IncidentCard extends StatelessWidget {
  final String id;
  final String type;
  final String roomNumber;
  final String aiSummary;
  final String description;
  final int severity;
  final String status;
  final String? assignedResponder;
  final int minutesElapsed;
  final VoidCallback? onAutoAssign;
  final DateTime? triageStartedAt;
  final DateTime? triageCompletedAt;

  final bool isMesh;

  const IncidentCard({
    super.key,
    required this.id,
    required this.type,
    required this.roomNumber,
    required this.aiSummary,
    required this.description,
    required this.severity,
    required this.status,
    this.assignedResponder,
    required this.minutesElapsed,
    this.onAutoAssign,
    this.isMesh = false,
    this.triageStartedAt,
    this.triageCompletedAt,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppColors.getSeverityColor(severity);
    final iconStr = type.toLowerCase() == 'fire' ? '🔥' : type.toLowerCase() == 'medical' ? '🏥' : type.toLowerCase() == 'security' ? '🔒' : '⚠️';
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: GestureDetector(
          onTap: () => context.push('/incident_detail/$id'),
          child: AnimatedScale(
            scale: isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.tc.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isHovered ? 0.2 : 0.1),
                    blurRadius: isHovered ? 20 : 15,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(
                  color: isHovered ? severityColor.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: severityColor,
                        ),
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
                                      color: severityColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(iconStr, style: const TextStyle(fontSize: 18)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Room $roomNumber",
                                                style: AppTextStyles.title.copyWith(fontSize: 18, fontWeight: FontWeight.w900, color: context.tc.textPrimary)),
                                            if (isMesh) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.red, width: 0.5),
                                                ),
                                                child: const Text("MESH", style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.w900)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(type.toUpperCase(),
                                            style: AppTextStyles.caption.copyWith(color: severityColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                      ],
                                    ),
                                  ),
                                  _buildTimeBadge(minutesElapsed),
                                ],
                              ),
                              if (triageStartedAt != null && triageCompletedAt != null) ...[
                                const SizedBox(height: 8),
                                _buildTriageBadge(),
                              ],
                              const SizedBox(height: 16),
                              Builder(builder: (context) {
                                final displayText = (aiSummary != null && aiSummary.isNotEmpty)
                                    ? aiSummary
                                    : description.isNotEmpty
                                        ? description
                                        : 'Processing...';

                                final isProcessing = aiSummary == null || aiSummary.isEmpty;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayText,
                                      style: AppTextStyles.body.copyWith(color: context.tc.textPrimary.withValues(alpha: 0.8), height: 1.5),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isProcessing) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "AI analyzing...",
                                          style: TextStyle(
                                            color: context.tc.textSecondary.withOpacity(0.5),
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  _buildStatusChip(status, severityColor),
                                  if (assignedResponder != null) ...[
                                    const SizedBox(width: 8),
                                    _buildResponderChip(assignedResponder!),
                                  ],
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBadge(int minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "${minutes}m ago",
        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildResponderChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, size: 10, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageBadge() {
    if (triageStartedAt == null || triageCompletedAt == null)
      return const SizedBox.shrink();

    final duration =
        triageCompletedAt!.difference(triageStartedAt!).inMilliseconds / 1000.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00D97E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00D97E).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF00D97E), size: 12),
          const SizedBox(width: 6),
          Text(
            "AI triaged in ${duration.toStringAsFixed(1)}s",
            style: const TextStyle(
                color: Color(0xFF00D97E),
                fontSize: 10,
                fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
