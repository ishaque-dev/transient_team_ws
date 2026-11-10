import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/config/app_config.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/di/di.dart';
import 'package:transient_team_ws/core/theme/theme_cubit.dart';
import 'package:transient_team_ws/core/utils/action_feedback.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/brand.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/subscription_card.dart';
import 'package:transient_team_ws/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:transient_team_ws/features/profile/presentation/pages/developer_contacts_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserEntity>();
    return BlocProvider(
      create: (_) => serviceLocator<ProfileCubit>(param1: user),
      child: BlocListener<ProfileCubit, ActionFeedback?>(
        listener: (context, feedback) {
          if (feedback != null) {
            showAppSnackBar(
              context,
              feedback.message,
              isError: feedback.isError,
            );
          }
        },
        child: _ProfileView(user: user),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user});

  final UserEntity user;

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: user.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.editName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: AppStrings.fullName),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && context.mounted) {
      await context.read<ProfileCubit>().updateName(name);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.signOut,
      message: AppStrings.signOutConfirm,
      confirmLabel: AppStrings.signOut,
    );
    if (confirmed && context.mounted) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = serviceLocator<AppConfig>();
    final themeMode = context.watch<ThemeCubit>().state;
    final flags = context.flags;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          GradientBanner(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: UserAvatar(name: user.displayName, size: 64),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isAdmin ? 'Admin · Owner' : 'Employee',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: AppStrings.account,
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                if (flags.editName)
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text(AppStrings.editName),
                    subtitle: Text(user.displayName),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editName(context),
                  ),
                if (flags.changePassword)
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded),
                    title: const Text(AppStrings.changePassword),
                    subtitle: const Text(AppStrings.changePasswordHint),
                    onTap: () =>
                        context.read<ProfileCubit>().sendPasswordReset(),
                  ),
                if (user.createdAt != null)
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text(AppStrings.memberSince),
                    subtitle: Text(Formatters.longDate(user.createdAt!)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SubscriptionCard(),
          if (flags.themeSwitch) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: AppStrings.appearance,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text(AppStrings.system),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text(AppStrings.light),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text(AppStrings.dark),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (value) =>
                    context.read<ThemeCubit>().setMode(value.first),
              ),
            ),
          ],
          if (flags.contactDeveloper) ...[
            const SizedBox(height: 12),
            const DeveloperContactsSection(),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const BrandMark(size: 36),
              title: Text(config.appTitle),
              subtitle: Text(AppStrings.appTagline),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
  }
}
