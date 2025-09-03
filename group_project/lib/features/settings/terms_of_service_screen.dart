import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SkillSwap Terms of Service',
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
              'Acceptance of Terms',
              'By downloading, installing, or using SkillSwap, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
            ),
            
            _buildSection(
              context,
              'Description of Service',
              'SkillSwap is a platform that connects individuals who want to learn new skills with those who can teach them. Users can create profiles, list their skills, search for skill partners, and arrange skill-sharing sessions.',
            ),
            
            _buildSection(
              context,
              'User Accounts',
              'You must create an account to use SkillSwap. You are responsible for maintaining the security of your account and all activities that occur under your account. You agree to provide accurate and complete information when creating your account.',
            ),
            
            _buildSection(
              context,
              'User Conduct',
              'You agree to use SkillSwap respectfully and lawfully. You will not:\n• Harass, abuse, or harm other users\n• Post inappropriate or offensive content\n• Use the service for commercial purposes without permission\n• Violate any applicable laws or regulations\n• Impersonate others or provide false information',
            ),
            
            _buildSection(
              context,
              'Privacy and Data',
              'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information. By using SkillSwap, you consent to the collection and use of your data as described in our Privacy Policy.',
            ),
            
            _buildSection(
              context,
              'Content and Intellectual Property',
              'You retain ownership of any content you post on SkillSwap. By posting content, you grant us a license to use, display, and distribute your content within the service. You may not post content that infringes on others\' intellectual property rights.',
            ),
            
            _buildSection(
              context,
              'Disclaimers',
              'SkillSwap is provided "as is" without warranties of any kind. We do not guarantee the quality, safety, or legality of skill-sharing sessions arranged through our platform. Users participate in skill-sharing activities at their own risk.',
            ),
            
            _buildSection(
              context,
              'Limitation of Liability',
              'SkillSwap and its developers shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the service, including but not limited to damages for loss of profits, data, or other intangible losses.',
            ),
            
            _buildSection(
              context,
              'Termination',
              'We may terminate or suspend your account at any time for violation of these terms. You may also delete your account at any time through the app settings. Upon termination, your right to use the service will cease immediately.',
            ),
            
            _buildSection(
              context,
              'Changes to Terms',
              'We reserve the right to modify these Terms of Service at any time. We will notify users of any material changes through the app or via email. Continued use of SkillSwap after changes constitutes acceptance of the new terms.',
            ),
            
            _buildSection(
              context,
              'Contact Information',
              'If you have any questions about these Terms of Service, please contact us through the app\'s Contact Us feature or at support@skillswap.app.',
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