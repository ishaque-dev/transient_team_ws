import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_bloc.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.onTap});

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getStatusColor() {
    switch (task.status) {
      case TaskStatus.completed:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.pending:
        return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskBloc>().add(DeleteTaskRequested(task.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    task.assignedUserId ?? 'Unassigned',
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(task.dueDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(
                    task.priority.name.toUpperCase(),
                    _getPriorityColor(),
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    task.status.name
                        .replaceAll(RegExp(r'(?=[A-Z])'), ' ')
                        .toUpperCase(),
                    _getStatusColor(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
