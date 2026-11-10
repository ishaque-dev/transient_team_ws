import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/core/theme/app_palette.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/pill.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';

/// Read-only subscription summary for the Profile tab.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final subscription = context.select(
      (AppControlCubit cubit) => cubit.state.subscription,
    );
    final muted = theme.colorScheme.onSurfaceVariant;

    if (subscription == null) {
      return SectionCard(
        title: 'Subscription',
        child: Text(
          'Subscription details are not available right now.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      );
    }

    final now = DateTime.now();
    final daysLeft = subscription.daysLeft(now);
    final valid = subscription.isValid(now);
    final endingSoon = valid && daysLeft != null && daysLeft <= 15;
    final (String status, Color color, IconData icon) = !valid
        ? (
            subscription.isSuspended ? 'Suspended' : 'Expired',
            palette.critical,
            Icons.error_outline_rounded,
          )
        : endingSoon
        ? ('Ending soon', palette.priorityHigh, Icons.schedule_rounded)
        : ('Active', palette.completed, Icons.verified_rounded);

    return SectionCard(
      title: 'Subscription',
      trailing: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Pill(label: status, color: color, icon: icon, dense: true),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${subscription.plan} plan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (subscription.validUntil != null)
            Text(
              'Valid until ${Formatters.longDate(subscription.validUntil!)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          if (valid && daysLeft != null) ...[
            const SizedBox(height: 12),
            Text(
              daysLeft == 0
                  ? 'Last day today'
                  : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
