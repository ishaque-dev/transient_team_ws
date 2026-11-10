import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';

class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _sendSetupEmail = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final ok = await context.read<TeamCubit>().addMember(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: UserRole.employee,
      sendPasswordSetupEmail: _sendSetupEmail,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addMember)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Create an employee account. They are active immediately and can '
              'sign in with this email.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: AppStrings.fullName,
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.enterName : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: AppStrings.email,
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) {
                final email = v?.trim() ?? '';
                if (email.isEmpty) return AppStrings.enterEmail;
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return AppStrings.enterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: AppStrings.temporaryPassword,
                prefixIcon: Icon(Icons.key_rounded),
                helperText: 'Share it with them privately.',
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? AppStrings.passwordTooShort
                  : null,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sendSetupEmail,
              onChanged: (value) => setState(() => _sendSetupEmail = value),
              title: const Text(AppStrings.sendResetLink),
              subtitle: const Text(AppStrings.sendResetLinkHint),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(AppStrings.addMember),
            ),
          ],
        ),
      ),
    );
  }
}
