import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  IconData _statusIcon() {
    switch (task.status) {
      case 'in_progress':
        return Icons.timelapse;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd/MM/yyyy');
    final done = task.status == 'completed';
    final barColor = PriorityBadge.color(task.priority);
    final statusColor = StatusBadge.color(task.status);

    int? daysLeft;
    if (task.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final d = task.dueDate!;
      daysLeft = DateTime(d.year, d.month, d.day).difference(today).inDays;
    }
    final overdue = daysLeft != null && daysLeft < 0 && !done;

    String? dueNote;
    if (daysLeft != null && !done) {
      if (daysLeft < 0) {
        dueNote = 'Quá hạn ${-daysLeft} ngày';
      } else if (daysLeft == 0) {
        dueNote = 'Hôm nay';
      } else if (daysLeft == 1) {
        dueNote = 'Ngày mai';
      } else {
        dueNote = 'Còn $daysLeft ngày';
      }
    }
    final dueColor = overdue
        ? scheme.error
        : (daysLeft != null && daysLeft <= 1 && !done)
            ? Colors.orange.shade800
            : scheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: barColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_statusIcon(), color: statusColor, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration:
                                        done ? TextDecoration.lineThrough : null,
                                    color: done ? scheme.onSurfaceVariant : null,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusBadge(status: task.status),
                            PriorityBadge(priority: task.priority),
                          ],
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Row(
                            children: [
                              Icon(Icons.event, size: 16, color: dueColor),
                              const SizedBox(width: 6),
                              Text(
                                '${fmt.format(task.dueDate!)}'
                                '${dueNote != null ? '  •  $dueNote' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: overdue ? FontWeight.w600 : null,
                                  color: dueColor,
                                ),
                              ),
                            ],
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
}