import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen displaying contact information and support options.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Get in Touch',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re here to help! Choose the best way to reach out to our team.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 179/255),
            ),
          ),
          const SizedBox(height: 32),

          // Email Contact
          _buildContactCard(
            context,
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@skillswap.app',
            description: 'For general inquiries, bug reports, and account issues',
            onTap: () => _handleEmailContact(context),
          ),

          const SizedBox(height: 16),

          // Feedback Contact
          _buildContactCard(
            context,
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts',
            description: 'Help us improve with your suggestions and ideas',
            onTap: () => Navigator.pushNamed(context, '/feedback'),
          ),

          const SizedBox(height: 16),

          // Business Contact
          _buildContactCard(
            context,
            icon: Icons.business,
            title: 'Business Inquiries',
            subtitle: 'business@skillswap.app',
            description: 'Partnerships, collaborations, and business opportunities',
            onTap: () => _handleBusinessContact(context),
          ),

          const SizedBox(height: 32),

          // Response Time Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Response Times',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildResponseTimeItem(
                    context,
                    'Critical Issues',
                    'Within 24 hours',
                    Icons.priority_high,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildResponseTimeItem(
                    context,
                    'General Support',
                    'Within 2-3 business days',
                    Icons.support,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildResponseTimeItem(
                    context,
                    'Feature Requests',
                    'Within 1 week',
                    Icons.lightbulb,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // FAQ Reference
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Before You Contact Us',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Check our Help Center for quick answers to common questions. You might find the solution you need right away!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/help'),
                      icon: const Icon(Icons.help_center),
                      label: const Text('Visit Help Center'),
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

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 25/255),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 179/255),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 128/255),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseTimeItem(
    BuildContext context,
    String type,
    String time,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          type,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 179/255),
          ),
        ),
      ],
    );
  }

  void _handleEmailContact(BuildContext context) {
    const email = 'support@skillswap.app';
    
    // Copy email to clipboard
    Clipboard.setData(const ClipboardData(text: email));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );

    // In a real app, you might also try to open an email client
    // using url_launcher package with mailto: scheme
  }

  void _handleBusinessContact(BuildContext context) {
    const email = 'business@skillswap.app';
    
    // Copy email to clipboard
    Clipboard.setData(const ClipboardData(text: email));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business email copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}