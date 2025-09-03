import 'package:flutter/material.dart';
import '../profile/edit_profile_screen.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: colorScheme.surface, // Changed from background to surface
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => _navigateToSetting(context, 'Edit Profile'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _navigateToSetting(context, 'Change Password'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.email_outlined,
            title: 'Change Email',
            onTap: () => _navigateToSetting(context, 'Change Email'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Account Verification',
            subtitle: 'Verify your identity',
            onTap: () => _navigateToSetting(context, 'Account Verification'),
          ),

          const SizedBox(height: 20),

          // Skills & Matching Section
          _buildSectionHeader(context, 'Skills & Matching'),
          _buildSettingsTile(
            context,
            icon: Icons.build_outlined,
            title: 'My Skills',
            subtitle: 'Manage skills you offer',
            onTap: () => _navigateToSetting(context, 'My Skills'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.school_outlined,
            title: 'Skills I Want to Learn',
            onTap: () => _navigateToSetting(context, 'Skills I Want to Learn'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.location_on_outlined,
            title: 'Location Preferences',
            subtitle: 'Search radius and availability',
            onTap: () => _navigateToSetting(context, 'Location Preferences'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.tune,
            title: 'Matching Preferences',
            onTap: () => _navigateToSetting(context, 'Matching Preferences'),
          ),

          const SizedBox(height: 20),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingsTile(
            context,
            icon: Icons.favorite_outline,
            title: 'New Match Notifications',
            onTap: () => _navigateToSetting(context, 'New Match Notifications'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.message_outlined,
            title: 'Message Notifications',
            onTap: () => _navigateToSetting(context, 'Message Notifications'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.handshake_outlined,
            title: 'Skill Request Notifications',
            onTap: () => _navigateToSetting(context, 'Skill Request Notifications'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.schedule,
            title: 'Do Not Disturb',
            subtitle: 'Set quiet hours',
            onTap: () => _navigateToSetting(context, 'Do Not Disturb'),
          ),

          const SizedBox(height: 20),

          // Privacy & Safety Section
          _buildSectionHeader(context, 'Privacy & Safety'),
          _buildSettingsTile(
            context,
            icon: Icons.visibility_outlined,
            title: 'Profile Visibility',
            subtitle: 'Control who can see your profile',
            onTap: () => _navigateToSetting(context, 'Profile Visibility'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.contact_mail_outlined,
            title: 'Contact Preferences',
            subtitle: 'Who can message you',
            onTap: () => _navigateToSetting(context, 'Contact Preferences'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.block,
            title: 'Blocked Users',
            onTap: () => _navigateToSetting(context, 'Blocked Users'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Data Privacy',
            onTap: () => _navigateToSetting(context, 'Data Privacy'),
          ),

          const SizedBox(height: 20),

          // App Preferences Section
          _buildSectionHeader(context, 'App Preferences'),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            subtitle: 'Light or dark mode',
            onTap: () => _navigateToSetting(context, 'Theme'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Language',
            onTap: () => _navigateToSetting(context, 'Language'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.storage_outlined,
            title: 'Storage & Cache',
            onTap: () => _navigateToSetting(context, 'Storage & Cache'),
          ),

          const SizedBox(height: 20),

          // Support Section
          _buildSectionHeader(context, 'Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => _navigateToSetting(context, 'Help Center'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.contact_support_outlined,
            title: 'Contact Us',
            onTap: () => _navigateToSetting(context, 'Contact Us'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.star_outline,
            title: 'Rate App',
            onTap: () => _navigateToSetting(context, 'Rate App'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            onTap: () => _navigateToSetting(context, 'Send Feedback'),
          ),

          const SizedBox(height: 20),

          // Legal Section
          _buildSectionHeader(context, 'Legal'),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _navigateToSetting(context, 'Terms of Service'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Privacy Policy',
            onTap: () => _navigateToSetting(context, 'Privacy Policy'),
          ),

          const SizedBox(height: 30),

          // Log Out Button - Now theme-aware
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error, // Use theme error color instead of Colors.red
                foregroundColor: colorScheme.onError, // Use theme onError color
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // App Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 179/255),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 179/255),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest, // Better surface color for cards
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: (theme.brightness == Brightness.dark ? 20 : 10)/255), // Adjusted shadow for dark mode
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(
          icon,
          color: colorScheme.onSurfaceVariant, // Better icon color
          size: 24,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 179/255),
          ),
        )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface.withValues(alpha: 102/255),
        ),
        onTap: onTap,
      ),
    );
  }

  void _navigateToSetting(BuildContext context, String setting) {
    switch (setting) {
      case 'Edit Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
        break;
      case 'Theme':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ThemeSettingsScreen(),
          ),
        );
        break;
      default:
      // Placeholder for other settings
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigate to: $setting'),
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your logout logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error, // Use theme error color instead of Colors.red
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}