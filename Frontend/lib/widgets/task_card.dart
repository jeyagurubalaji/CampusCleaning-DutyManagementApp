import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/constants.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final CleaningTask task;
  final VoidCallback? onTap;
  final Widget? actions;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    task.room?.type == 'laboratory'
                        ? Icons.science
                        : Icons.meeting_room,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.room?.name ?? 'Unknown Room',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${task.room?.roomNumber ?? ''} • Floor ${task.room?.floor ?? '-'}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: task.status),
                ],
              ),
              const SizedBox(height: 12),
              if (task.room?.department != null)
                Text(
                  'Dept: ${task.room!.department!.name}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              if (task.sweeper != null)
                Text(
                  'Sweeper: ${task.sweeper!.name}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              const SizedBox(height: 4),
              Text(
                'Duty Date: ${DateFormat('dd MMM yyyy').format(task.dutyDate)}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (task.completedAt != null)
                Text(
                  'Completed: ${DateFormat('dd MMM yyyy, hh:mm a').format(task.completedAt!.toLocal())}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              if (task.isRejected && task.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.rejectionReason!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (actions != null) ...[
                const SizedBox(height: 12),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}