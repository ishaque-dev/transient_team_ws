import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/task_form_page.dart';

class TaskDetailsPage extends StatelessWidget {
  final TaskEntity task;

  const TaskDetailsPage({super.key, required this.task});

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
              Navigator.pop(dialogContext); // Pop Dialog
              Navigator.pop(context); // Pop Details Page
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        // Find the most recent version of this task from the Bloc state
        final currentTask = state.tasks.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TaskBloc>(),
                        child: TaskFormPage(task: currentTask),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBadge(
                      currentTask.priority.name.toUpperCase(),
                      _getPriorityColor(currentTask.priority),
                    ),
                    const SizedBox(width: 12),
                    _buildBadge(
                      currentTask.status.name
                          .replaceAll(RegExp(r'(?=[A-Z])'), ' ')
                          .toUpperCase(),
                      _getStatusColor(currentTask.status),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  currentTask.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  currentTask.description,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow(
                    Icons.calendar_today,
                    'Due Date',
                    DateFormat('EEEE, MMM dd, yyyy')
                        .format(currentTask.dueDate)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.person_outline, 'Assigned To',
                    currentTask.assignedUserId ?? 'Unassigned'),
                const SizedBox(height: 48),
                _buildActionButton(context, currentTask),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, TaskEntity currentTask) {
    final isCompleted = currentTask.status == TaskStatus.completed;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          final updatedTask = currentTask.copyWith(
            status: isCompleted ? TaskStatus.pending : TaskStatus.completed,
          );
          context.read<TaskBloc>().add(UpdateTaskRequested(updatedTask));
        },
        icon: Icon(isCompleted ? Icons.replay : Icons.check_circle_outline),
        label: Text(isCompleted ? 'Reopen Task' : 'Mark as Completed'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.orange : Colors.green,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.pending:
        return Colors.grey;
    }
  }
}
