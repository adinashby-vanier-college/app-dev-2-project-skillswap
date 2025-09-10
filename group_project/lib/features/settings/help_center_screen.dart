import 'package:flutter/material.dart';

/// Screen displaying help and FAQ information.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Frequently Asked Questions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildFAQItem(
            context,
            'How do I find skill partners?',
            'Use the search feature on the home screen to find people who offer skills you want to learn, or browse through the matches section to see suggested partners based on your profile.',
          ),
          
          _buildFAQItem(
            context,
            'How do I add or edit my skills?',
            'Go to Settings > My Skills to add skills you can teach and skills you want to learn. Make sure to keep your skills updated to get better matches.',
          ),
          
          _buildFAQItem(
            context,
            'How does the matching system work?',
            'Our algorithm matches you with people based on complementary skills - if you want to learn something they can teach, or vice versa. Location and availability are also considered.',
          ),
          
          _buildFAQItem(
            context,
            'How do I propose a skill-sharing session?',
            'In any chat conversation, tap the calendar icon to propose a session. You can specify the skill, duration, location, and preferred time.',
          ),
          
          _buildFAQItem(
            context,
            'Are skill-sharing sessions free?',
            'SkillSwap promotes free skill exchange between users. However, users may agree on their own arrangements for materials, travel costs, or other expenses.',
          ),
          
          _buildFAQItem(
            context,
            'How do I manage notifications?',
            'Go to Settings and tap on any of the notification options to access the notification center where you can customize your preferences.',
          ),
          
          _buildFAQItem(
            context,
            'How do I archive or delete conversations?',
            'In any chat, tap the archive icon in the top-right corner. You can view archived chats from the conversations screen menu.',
          ),
          
          _buildFAQItem(
            context,
            'How do I report inappropriate behavior?',
            'If you encounter inappropriate behavior, please use the Contact Us feature to report it. We take safety seriously and will investigate all reports.',
          ),
          
          _buildFAQItem(
            context,
            'Can I change my profile information?',
            'Yes! Go to Settings > Edit Profile to update your name, bio, location, and profile photo at any time.',
          ),
          
          _buildFAQItem(
            context,
            'How do I delete my account?',
            'Account deletion can be requested through the Contact Us feature. Please note that this action is permanent and cannot be undone.',
          ),
          
          _buildFAQItem(
            context,
            'Why am I not getting matches?',
            'Make sure your profile is complete with skills and a good bio. Check that your location is set correctly. Try expanding your skill interests or updating your profile regularly.',
          ),
          
          _buildFAQItem(
            context,
            'How do I change app themes?',
            'Go to Settings > Theme to switch between light and dark mode, or let the app follow your device\'s system setting.',
          ),
          
          const SizedBox(height: 32),
          
          // Contact section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Need More Help?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you can\'t find the answer to your question, feel free to contact our support team. We\'re here to help!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // This would navigate to contact us
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Redirecting to Contact Us...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.contact_support),
                      label: const Text('Contact Support'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}