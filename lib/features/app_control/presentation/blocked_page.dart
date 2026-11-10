import 'package:flutter/material.dart';
import 'package:transient_team_ws/core/theme/app_theme.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/brand.dart';
import 'package:transient_team_ws/core/widgets/contact_options.dart';
import 'package:transient_team_ws/features/app_control/domain/feature_flags.dart';
import 'package:transient_team_ws/features/app_control/domain/subscription_entity.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';

/// Replaces the whole app when it is switched off or the subscription is no
/// longer valid.
class BlockedPage extends StatelessWidget {
  const BlockedPage({
    super.key,
    required this.reason,
    required this.flags,
    this.subscription,
  });

  final BlockReason reason;
  final FeatureFlags flags;
  final SubscriptionEntity? subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = reason == BlockReason.appDisabled;
    final end = subscription?.validUntil;

    final title = disabled
        ? flags.appBlockedTitle
        : (subscription?.isSuspended ?? false)
        ? 'Subscription suspended'
        : 'Subscription expired';
    final detail = disabled
        ? flags.appBlockedMessage
        : [
            if (end != null && !(subscription?.isSuspended ?? false))
              'Your plan ended on ${Formatters.longDate(end)}.',
            flags.subscriptionExpiredMessage,
          ].join(' ');

    return Scaffold(
      backgroundColor: BrandColors.purple,
      body: BrandBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const CoopiqLogo(width: 200),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        disabled
                            ? Icons.power_settings_new_rounded
                            : Icons.workspace_premium_rounded,
                        color: BrandColors.orange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Contact me',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ContactOptions(
                      phone: flags.contactPhone,
                      email: flags.contactEmail,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
