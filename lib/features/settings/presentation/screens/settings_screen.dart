import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
