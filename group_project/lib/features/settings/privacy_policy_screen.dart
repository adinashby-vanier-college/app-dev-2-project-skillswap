import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SkillSwap Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: January 2025',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 153/255),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Introduction',
              'SkillSwap respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our skill-sharing platform.',
            ),
            
            _buildSection(
              context,
              'Information We Collect',
              'We collect the following types of information:\n\n• Account Information: Name, email address, profile photo\n• Profile Data: Skills you offer, skills you want to learn, location, bio\n• Usage Data: App interactions, session history, messages\n• Device Information: Device type, operating system, app version\n• Location Data: Approximate location for matching purposes (with your consent)',
            ),
            
            _buildSection(
              context,
              'How We Use Your Information',
              'We use your information to:\n\n• Provide and improve our skill-sharing service\n• Match you with relevant skill partners\n• Send notifications about matches and messages\n• Ensure platform safety and security\n• Analyze app usage to enhance user experience\n• Communicate important updates about the service',
            ),
            
            _buildSection(
              context,
              'Information Sharing',
              'We do not sell your personal information. We may share limited information in these situations:\n\n• With other users: Your profile information (name, skills, bio) for matching purposes\n• Service Providers: Trusted third parties who help us operate the app\n• Legal Requirements: When required by law or to protect our rights\n• Business Transfers: In case of merger or acquisition (with notice)',
            ),
            
            _buildSection(
              context,
              'Data Security',
              'We implement appropriate security measures to protect your information:\n\n• Encryption of data in transit and at rest\n• Regular security assessments and updates\n• Limited access to personal information\n• Secure authentication systems\n\nHowever, no method of transmission over the internet is 100% secure.',
            ),
            
            _buildSection(
              context,
              'Data Retention',
              'We retain your information for as long as your account is active or as needed to provide services. You can delete your account at any time through the app settings, which will remove your personal information from our systems.',
            ),
            
            _buildSection(
              context,
              'Your Rights and Choices',
              'You have the right to:\n\n• Access and update your personal information\n• Delete your account and associated data\n• Control notification preferences\n• Opt out of location tracking\n• Request a copy of your data\n• Contact us with privacy concerns',
            ),
            
            _buildSection(
              context,
              'Cookies and Tracking',
              'SkillSwap uses minimal tracking technologies:\n\n• Essential cookies for app functionality\n• Analytics to understand app usage patterns\n• Push notification tokens for messaging\n\nWe do not use advertising cookies or sell data to advertisers.',
            ),
            
            _buildSection(
              context,
              'Children\'s Privacy',
              'SkillSwap is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we discover we have collected information from a child under 13, we will delete it immediately.',
            ),
            
            _buildSection(
              context,
              'International Data Transfers',
              'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information during international transfers.',
            ),
            
            _buildSection(
              context,
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any material changes through the app or via email. Your continued use of SkillSwap after changes constitutes acceptance of the updated policy.',
            ),
            
            _buildSection(
              context,
              'Contact Us',
              'If you have questions about this Privacy Policy or how we handle your data, please contact us:\n\n• Through the app\'s Contact Us feature\n• Email: privacy@skillswap.app\n• Address: [Your business address]',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}