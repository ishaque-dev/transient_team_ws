import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/constants/mock_data.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_bloc.dart';

class TaskFormPage extends StatefulWidget {
  final TaskEntity? task;

  const TaskFormPage({super.key, this.task});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskPriority _selectedPriority;
  late TaskStatus _selectedStatus;
  String? _selectedAssignee;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.dueDate ?? DateTime.now();
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _selectedStatus = widget.task?.status ?? TaskStatus.pending;
    _selectedAssignee = widget.task?.assignedUserId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      // Restriction: Dates cannot be in the past
      firstDate: DateTime.now().subtract(const Duration(minutes: 1)),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = TaskEntity(
        id: widget.task?.id ?? '', // ID generated in Use Case if empty
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDate,
        status: _selectedStatus,
        assignedUserId: _selectedAssignee,
      );

      if (_isEditing) {
        context.read<TaskBloc>().add(UpdateTaskRequested(task));
      } else {
        context.read<TaskBloc>().add(CreateTaskRequested(task));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editTask : AppStrings.newTask),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: AppStrings.title,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? AppStrings.enterTitle : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: AppStrings.description,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty)
                    ? AppStrings.enterDescription
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(AppStrings.priority,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedPriority = value!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text(AppStrings.assignTo,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedAssignee,
                hint: const Text(AppStrings.selectTeamMember),
                items: MockData.teamMembers.map((member) {
                  return DropdownMenuItem(
                    value: member,
                    child: Text(member),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedAssignee = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                const Text(AppStrings.status,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<TaskStatus>(
                  initialValue: _selectedStatus,
                  items: TaskStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 16),
              const Text(AppStrings.dueDate,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(AppStrings.saveTask, style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
