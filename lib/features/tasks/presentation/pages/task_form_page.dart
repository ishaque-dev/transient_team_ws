import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_actions_cubit.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/assignee_picker.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_visuals.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';

/// Create (no [task]) or edit a task. Admin only.
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.task, this.initialAssigneeId});

  final TaskEntity? task;

  /// Preselects an assignee when creating from an employee's page.
  final String? initialAssigneeId;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _dueDate;
  late TaskPriority _priority;
  late TaskStatus _status;
  String? _assigneeId;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title)..addListener(_markDirty);
    _description = TextEditingController(text: task?.description)
      ..addListener(_markDirty);
    _dueDate =
        task?.dueDate ?? dateOnly(DateTime.now().add(const Duration(days: 1)));
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.todo;
    _assigneeId = task?.assigneeId ?? widget.initialAssigneeId;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _update(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    // Editing an overdue task must still allow its current (past) due date.
    final first = _dueDate.isBefore(today) ? _dueDate : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: first,
      lastDate: DateTime(today.year + 3, 12, 31),
    );
    if (picked != null) _update(() => _dueDate = dateOnly(picked));
  }

  Future<void> _pickAssignee(List<UserEntity> assignable) async {
    final tasks = context.read<TaskListBloc>().state.tasks;
    final openCounts = <String, int>{};
    for (final task in tasks) {
      final id = task.assigneeId;
      if (id != null && task.status.isOpen) {
        openCounts[id] = (openCounts[id] ?? 0) + 1;
      }
    }
    final choice = await showAssigneePicker(
      context,
      members: assignable,
      selectedId: _assigneeId,
      openTaskCounts: openCounts,
    );
    if (choice != null) _update(() => _assigneeId = choice.userId);
  }

  Future<void> _save(List<UserEntity> assignable) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final assignee = assignable.where((m) => m.id == _assigneeId).firstOrNull;
    final actions = context.read<TaskActionsCubit>();
    final ok = _isEditing
        ? await actions.update(
            original: widget.task!,
            title: _title.text,
            description: _description.text,
            priority: _priority,
            status: _status,
            dueDate: _dueDate,
            assignee: assignee,
          )
        : await actions.create(
            title: _title.text,
            description: _description.text,
            priority: _priority,
            dueDate: _dueDate,
            assignee: assignee,
          );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() {
    return showConfirmDialog(
      context,
      title: AppStrings.discardChangesTitle,
      message: AppStrings.discardChangesBody,
      confirmLabel: AppStrings.discard,
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team = context.watch<TeamCubit>().state;
    final assignable = [
      ...team.assignable,
      // Keep a deactivated current assignee selectable so the field is valid.
      if (_assigneeId != null &&
          !team.assignable.any((m) => m.id == _assigneeId))
        ?team.byId(_assigneeId),
    ];
    final today = dateOnly(DateTime.now());

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? AppStrings.editTask : AppStrings.newTask),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              TextFormField(
                controller: _title,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: AppStrings.title,
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? AppStrings.enterTitle
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: AppStrings.description,
                  hintText: AppStrings.descriptionHint,
                  alignLabelWithHint: true,
                ),
              ),
              label(AppStrings.assignedTo),
              Builder(
                builder: (context) {
                  final selected = assignable
                      .where((m) => m.id == _assigneeId)
                      .firstOrNull;
                  return PickerField(
                    leading: selected == null
                        ? const PickerIcon(Icons.person_add_alt_rounded)
                        : UserAvatar(name: selected.displayName, size: 36),
                    title: selected?.displayName ?? 'Choose an employee',
                    subtitle: selected?.email ?? 'Or leave it unassigned',
                    placeholder: selected == null,
                    onTap: () => _pickAssignee(assignable),
                  );
                },
              ),
              label(AppStrings.dueDate),
              PickerField(
                leading: const PickerIcon(Icons.event_rounded),
                title: Formatters.longDate(_dueDate),
                subtitle: Formatters.dueLabel(_dueDate),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (text, days) in const [
                    ('Today', 0),
                    ('Tomorrow', 1),
                    ('In 3 days', 3),
                    ('Next week', 7),
                  ])
                    ActionChip(
                      label: Text(text),
                      onPressed: () => _update(
                        () => _dueDate = DateTime(
                          today.year,
                          today.month,
                          today.day + days,
                        ),
                      ),
                    ),
                ],
              ),
              label(AppStrings.priority),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final priority in TaskPriority.values)
                    ChoiceChip(
                      avatar: Icon(
                        priority.icon,
                        color: priority.color(context),
                      ),
                      label: Text(priority.label),
                      selected: _priority == priority,
                      showCheckmark: false,
                      onSelected: (_) => _update(() => _priority = priority),
                    ),
                ],
              ),
              if (_isEditing) ...[
                label(AppStrings.status),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in TaskStatus.values)
                      ChoiceChip(
                        avatar: Icon(status.icon, color: status.color(context)),
                        label: Text(status.label),
                        selected: _status == status,
                        showCheckmark: false,
                        onSelected: (_) => _update(() => _status = status),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(assignable),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isEditing
                            ? Icons.save_rounded
                            : Icons.add_task_rounded,
                      ),
                label: Text(
                  _isEditing ? AppStrings.saveChanges : AppStrings.createTask,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
