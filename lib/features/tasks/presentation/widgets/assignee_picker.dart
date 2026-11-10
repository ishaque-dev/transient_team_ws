import 'package:flutter/material.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

/// Compact, tappable form field: leading visual, a title with an optional
/// subtitle, and a chevron. Replaces the default dropdown look.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.placeholder = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Renders [title] in the muted hint style (nothing chosen yet).
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: placeholder ? null : FontWeight.w600,
                        color: placeholder ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular icon used as [PickerField.leading] when there is no avatar.
class PickerIcon extends StatelessWidget {
  const PickerIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 18,
      backgroundColor: scheme.primaryContainer,
      child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
    );
  }
}

/// The picker's answer. `null` from [showAssigneePicker] means dismissed;
/// a choice with a null [userId] means "Unassigned".
class AssigneeChoice {
  const AssigneeChoice(this.userId);

  final String? userId;
}

Future<AssigneeChoice?> showAssigneePicker(
  BuildContext context, {
  required List<UserEntity> members,
  required String? selectedId,
  required Map<String, int> openTaskCounts,
}) {
  return showModalBottomSheet<AssigneeChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _AssigneeSheet(
      members: members,
      selectedId: selectedId,
      openTaskCounts: openTaskCounts,
    ),
  );
}

class _AssigneeSheet extends StatefulWidget {
  const _AssigneeSheet({
    required this.members,
    required this.selectedId,
    required this.openTaskCounts,
  });

  final List<UserEntity> members;
  final String? selectedId;
  final Map<String, int> openTaskCounts;

  @override
  State<_AssigneeSheet> createState() => _AssigneeSheetState();
}

class _AssigneeSheetState extends State<_AssigneeSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final needle = _query.trim().toLowerCase();
    final members =
        widget.members
            .where(
              (m) =>
                  needle.isEmpty ||
                  m.displayName.toLowerCase().contains(needle) ||
                  m.email.toLowerCase().contains(needle),
            )
            .toList()
          ..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );

    void pick(String? id) => Navigator.pop(context, AssigneeChoice(id));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Assign to',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.members.length > 5)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchBar(
                  hintText: 'Search employees',
                  elevation: const WidgetStatePropertyAll(0),
                  leading: const Icon(Icons.search_rounded),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                children: [
                  if (needle.isEmpty)
                    _Option(
                      selected: widget.selectedId == null,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person_off_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      title: AppStrings.unassigned,
                      subtitle: 'Keep it in the backlog for now',
                      onTap: () => pick(null),
                    ),
                  if (widget.members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No active employees yet. Add them from the Team tab.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else if (members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No one matches “$_query”.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final member in members)
                    _Option(
                      selected: member.id == widget.selectedId,
                      leading: UserAvatar(name: member.displayName),
                      title: member.displayName,
                      subtitle: member.email,
                      trailing: _LoadChip(
                        open: widget.openTaskCounts[member.id] ?? 0,
                      ),
                      onTap: () => pick(member.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.selected,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final bool selected;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.secondaryContainer.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: leading,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?trailing,
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// "3 open" workload hint, so admins can spread work evenly.
class _LoadChip extends StatelessWidget {
  const _LoadChip({required this.open});

  final int open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        open == 0 ? 'Free' : '$open open',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
