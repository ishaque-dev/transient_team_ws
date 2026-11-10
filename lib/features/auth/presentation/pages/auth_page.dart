import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/theme/app_theme.dart';
import 'package:transient_team_ws/core/widgets/brand.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<AuthBloc>();
    if (_isLogin ||
        !context.read<AppControlCubit>().state.flags.requestAccess) {
      bloc.add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } else {
      bloc.add(
        AuthSignUpRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.resetPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.resetPasswordBody),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: AppStrings.email,
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text(AppStrings.sendLink),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || email == null) return;
    context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          showAppSnackBar(context, state.message, isError: true);
        } else if (state is AuthNotice) {
          showAppSnackBar(context, state.message);
          if (!_isLogin) setState(() => _isLogin = true);
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.purple,
        body: BrandBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: CoopiqLogo(width: 230)),
                      const SizedBox(height: 4),
                      Text(
                        'INTERNAL',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.appTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        elevation: 12,
                        shadowColor: Colors.black.withValues(alpha: 0.35),
                        color: scheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildForm(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final flags = context.flags;
    // If self sign-up gets switched off while the form is open, fall back.
    final isLogin = _isLogin || !flags.requestAccess;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (flags.requestAccess)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text(AppStrings.signIn),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(AppStrings.requestAccess),
                      ),
                    ],
                    selected: {_isLogin},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: BrandColors.purple,
                      selectedForegroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onSelectionChanged: isLoading
                        ? null
                        : (value) => setState(() => _isLogin = value.first),
                  ),
                const SizedBox(height: 20),
                if (flags.googleSignIn) ...[
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                            AuthGoogleSignInRequested(),
                          ),
                    icon: const GoogleLogo(),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or with email',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (!isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: AppStrings.fullName,
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? AppStrings.enterName
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return AppStrings.enterEmail;
                    if (!_emailPattern.hasMatch(email)) {
                      return AppStrings.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: isLogin
                      ? TextInputAction.done
                      : TextInputAction.next,
                  autofillHints: [
                    isLogin
                        ? AutofillHints.password
                        : AutofillHints.newPassword,
                  ],
                  onFieldSubmitted: (_) => isLogin ? _submit() : null,
                  decoration: InputDecoration(
                    labelText: AppStrings.password,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.enterPassword;
                    }
                    if (value.length < 6) return AppStrings.passwordTooShort;
                    return null;
                  },
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.confirmPassword,
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? AppStrings.passwordsDoNotMatch
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 20,
                          color: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.approvalHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isLogin && flags.forgotPassword)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _forgotPassword,
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  )
                else
                  const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          isLogin
                              ? AppStrings.signIn
                              : AppStrings.requestAccess,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
