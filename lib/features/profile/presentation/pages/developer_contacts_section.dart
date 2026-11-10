import 'package:flutter/material.dart';
import 'package:transient_team_ws/core/widgets/contact_options.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';

/// Profile row that opens the contact-the-developer sheet.
class DeveloperContactsSection extends StatelessWidget {
  const DeveloperContactsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final flags = context.flags;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            Icons.support_agent_rounded,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: const Text(
          'Contact developer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('WhatsApp, call or email'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          useSafeArea: true,
          builder: (sheetContext) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Need help?',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reach the developer directly',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ContactOptions(
                  phone: flags.contactPhone,
                  email: flags.contactEmail,
                  onLaunched: () => Navigator.of(sheetContext).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
