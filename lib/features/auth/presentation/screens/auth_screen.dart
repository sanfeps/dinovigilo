import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/core/error/failures.dart';
import 'package:dinovigilo/core/utils/result.dart';
import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.startInSignUp = false});

  final bool startInSignUp;

  static Future<void> push(
    BuildContext context, {
    bool signUp = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(startInSignUp: signUp),
      ),
    );
  }

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthMode { signIn, signUp }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  late _AuthMode _mode =
      widget.startInSignUp ? _AuthMode.signUp : _AuthMode.signIn;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  bool get _isSignUp => _mode == _AuthMode.signUp;

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.emailRequired;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return context.l10n.invalidEmail;
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return context.l10n.passwordRequired;
    if (_isSignUp && v.length < 8) return context.l10n.passwordTooShort;
    return null;
  }

  String? _validateUsername(String? value) {
    if (!_isSignUp) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.usernameRequired;
    return null;
  }

  String? _validateDisplayName(String? value) {
    if (!_isSignUp) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.displayNameRequired;
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final Result<AuthSession> result;
      if (_isSignUp) {
        final useCase = await ref.read(signUpUseCaseProvider.future);
        result = await useCase.execute(
          email: email,
          password: password,
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );
      } else {
        final useCase = await ref.read(signInUseCaseProvider.future);
        result = await useCase.execute(
          identity: email,
          password: password,
        );
      }

      if (!mounted) return;
      result.when(
        success: (_) {
          context.showSnackBar(
            _isSignUp ? context.l10n.accountCreated : context.l10n.welcomeBackUser,
          );
          Navigator.of(context).pop();
        },
        failure: (failure) {
          context.showSnackBar(_failureMessage(failure), isError: true);
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _failureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => context.l10n.errorNetwork,
      AuthFailure() => context.l10n.errorInvalidCredentials,
      ValidationFailure(:final message) => message,
      _ => context.l10n.errorGeneric,
    };
  }

  void _toggleMode() {
    setState(() {
      _mode = _isSignUp ? _AuthMode.signIn : _AuthMode.signUp;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? context.l10n.signUp : context.l10n.signIn;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  '🦖',
                  style: context.textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: context.l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    enabled: !_submitting,
                    decoration: InputDecoration(
                      labelText: context.l10n.username,
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    textInputAction: TextInputAction.next,
                    enabled: !_submitting,
                    decoration: InputDecoration(
                      labelText: context.l10n.displayName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: _validateDisplayName,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_submitting,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: context.l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(title),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _submitting ? null : _toggleMode,
                  child: Text(
                    _isSignUp
                        ? context.l10n.alreadyHaveAccount
                        : context.l10n.dontHaveAccount,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
