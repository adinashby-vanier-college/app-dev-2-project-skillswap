import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// Screen for managing app theme settings.
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Theme'),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
          ),
          backgroundColor: colorScheme.surface,
          body: ListView(
            children: [
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: (theme.brightness == Brightness.dark ? 20 : 10)/255),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface, // Theme-aware text color
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildThemeOption(
                      context,
                      'light',
                      'Light',
                      'Always use light theme',
                      Icons.light_mode,
                      themeProvider.themeString,
                      themeProvider,
                    ),
                    _buildThemeOption(
                      context,
                      'dark',
                      'Dark',
                      'Always use dark theme',
                      Icons.dark_mode,
                      themeProvider.themeString,
                      themeProvider,
                    ),
                    _buildThemeOption(
                      context,
                      'system',
                      'System Default',
                      'Follow system theme setting',
                      Icons.settings_system_daydream,
                      themeProvider.themeString,
                      themeProvider,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
      BuildContext context,
      String value,
      String title,
      String subtitle,
      IconData icon,
      String currentTheme,
      ThemeProvider themeProvider
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentTheme == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          themeProvider.setTheme(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Theme changed to: $title'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? colorScheme.primary.withValues(alpha: 25/255) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant, // Theme-aware icon color
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface, // Theme-aware text color
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant, // Theme-aware subtitle color
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}