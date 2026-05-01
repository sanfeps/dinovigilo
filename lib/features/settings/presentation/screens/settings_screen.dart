import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dinovigilo/features/auth/domain/entities/auth_session.dart';
import 'package:dinovigilo/features/auth/presentation/providers/auth_providers.dart';
import 'package:dinovigilo/features/auth/presentation/screens/auth_screen.dart';
import 'package:dinovigilo/features/friends/presentation/screens/friends_screen.dart';
import 'package:dinovigilo/features/settings/presentation/providers/settings_providers.dart';
import 'package:dinovigilo/shared/extensions/context_extensions.dart';
import 'package:dinovigilo/shared/theme/app_colors.dart';
import 'package:dinovigilo/shared/widgets/loading_indicator.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
      ),
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account Section
              Text(
                context.l10n.account,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const _AccountCard(),
              const SizedBox(height: 24),
              // Notifications Section
              Text(
                context.l10n.notifications,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(context.l10n.enableNotifications),
                      value: settings.notificationsEnabled,
                      onChanged: (value) {
                        ref
                            .read(appSettingsNotifierProvider.notifier)
                            .toggleNotifications(value);
                      },
                    ),
                    ListTile(
                      title: Text(context.l10n.dailyReminderTime),
                      trailing: Text(
                        TimeOfDay(
                          hour: settings.reminderHour,
                          minute: settings.reminderMinute,
                        ).format(context),
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: settings.notificationsEnabled
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
                      enabled: settings.notificationsEnabled,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: settings.reminderHour,
                            minute: settings.reminderMinute,
                          ),
                        );
                        if (time != null) {
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .updateReminderTime(time.hour, time.minute);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Language Section
              Text(
                context.l10n.language,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<String?>(
                    segments: [
                      ButtonSegment(
                        value: null,
                        label: Text(context.l10n.systemDefault),
                      ),
                      ButtonSegment(
                        value: 'en',
                        label: Text(context.l10n.english),
                      ),
                      ButtonSegment(
                        value: 'es',
                        label: Text(context.l10n.spanish),
                      ),
                    ],
                    selected: {settings.localeOverride},
                    onSelectionChanged: (selection) {
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .updateLocale(selection.first);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // About Section
              Text(
                context.l10n.about,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DinoVigilo',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.l10n.version} 1.0.0',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build streaks, hatch dinosaurs',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);

    return Card(
      child: sessionAsync.when(
        data: (session) => session == null
            ? _SignedOutTile(
                onSignIn: () => AuthScreen.push(context),
                onSignUp: () => AuthScreen.push(context, signUp: true),
              )
            : _SignedInTile(
                session: session,
                onSignOut: () => _signOut(ref),
              ),
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => _SignedOutTile(
          onSignIn: () => AuthScreen.push(context),
          onSignUp: () => AuthScreen.push(context, signUp: true),
        ),
      ),
    );
  }

  Future<void> _signOut(WidgetRef ref) async {
    final useCase = await ref.read(signOutUseCaseProvider.future);
    await useCase.execute();
  }
}

class _SignedOutTile extends StatelessWidget {
  const _SignedOutTile({required this.onSignIn, required this.onSignUp});

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.notSignedIn,
            style: context.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.signInToConnect,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSignIn,
                  child: Text(context.l10n.signIn),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onSignUp,
                  child: Text(context.l10n.signUp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignedInTile extends StatelessWidget {
  const _SignedInTile({required this.session, required this.onSignOut});

  final AuthSession session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              session.user.avatarEmoji.isEmpty
                  ? '🦖'
                  : session.user.avatarEmoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(session.user.displayName.isEmpty
              ? session.user.username
              : session.user.displayName),
          subtitle: Text('@${session.user.username}'),
          trailing: TextButton(
            onPressed: onSignOut,
            child: Text(context.l10n.signOut),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text(context.l10n.friends),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => FriendsScreen.push(context),
        ),
      ],
    );
  }
}
