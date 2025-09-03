import 'package:flutter/material.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/edit_skills_screen.dart';
import '../notifications/notifications_screen.dart';
import 'theme_settings_screen.dart';
import '../notifications/fcm_test_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_center_screen.dart';
import 'send_feedback_screen.dart';
import 'contact_us_screen.dart';

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

          // Developer Options Section
          _buildSectionHeader(context, 'Developer Options'),
          _buildSettingsTile(
            context,
            icon: Icons.bug_report,
            title: 'Notification Testing',
            subtitle: 'Test push notifications & FCM',
            onTap: () => _navigateToSetting(context, 'FCM Test'),
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
      case 'My Skills':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditSkillsScreen(),
          ),
        );
        break;
      case 'New Match Notifications':
      case 'Message Notifications':
      case 'Skill Request Notifications':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
        break;
      case 'FCM Test':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FCMTestScreen(),
          ),
        );
        break;
      case 'Terms of Service':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsOfServiceScreen(),
          ),
        );
        break;
      case 'Privacy Policy':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacyPolicyScreen(),
          ),
        );
        break;
      case 'Help Center':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HelpCenterScreen(),
          ),
        );
        break;
      case 'Send Feedback':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SendFeedbackScreen(),
          ),
        );
        break;
      case 'Contact Us':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContactUsScreen(),
          ),
        );
        break;
      case 'Rate App':
        _rateApp(context);
        break;
      default:
      // Coming soon for other settings
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$setting - Coming Soon!'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    // Show a dialog asking user to rate
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate SkillSwap'),
          content: const Text('Enjoying SkillSwap? Please take a moment to rate us on the app store!'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openAppStore();
              },
              child: const Text('Rate Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAppStore() async {
    // In a real app, these would be your actual app store URLs
    // const androidUrl = 'https://play.google.com/store/apps/details?id=com.skillswap.app';
    // const iosUrl = 'https://apps.apple.com/app/skillswap/id123456789';
    
    try {
      // Try to launch the appropriate URL based on platform
      // For now, just show a message since we don't have actual store URLs
      // await launchUrl(Uri.parse(androidUrl));
      
      // Placeholder action
      await Future.delayed(const Duration(milliseconds: 500));
      // Show confirmation that we would open the store
    } catch (e) {
      // Handle error - could show a snackbar
      debugPrint('Could not launch app store: $e');
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