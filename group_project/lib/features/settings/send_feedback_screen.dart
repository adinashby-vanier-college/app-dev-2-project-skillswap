import 'package:flutter/material.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  String _feedbackType = 'General';
  bool _isSubmitting = false;

  final List<String> _feedbackTypes = [
    'General',
    'Bug Report',
    'Feature Request',
    'User Experience',
    'Performance Issue',
    'Content Issue',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Simulate sending feedback
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback! We\'ll review it and get back to you.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'We value your feedback!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve SkillSwap by sharing your thoughts, reporting bugs, or suggesting new features.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 179/255),
              ),
            ),
            const SizedBox(height: 32),

            // Feedback Type Dropdown
            Text(
              'Feedback Type',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _feedbackType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _feedbackTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getFeedbackIcon(type), size: 20),
                      const SizedBox(width: 12),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _feedbackType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Feedback Text Area
            Text(
              'Your Feedback',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _feedbackController,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Please describe your feedback in detail...',
                contentPadding: EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your feedback';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Sending...' : 'Send Feedback'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Feedback Guidelines',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Be specific about the issue or suggestion\n'
                      '• Include steps to reproduce bugs if applicable\n'
                      '• Mention your device type and app version for technical issues\n'
                      '• Keep feedback constructive and respectful',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 179/255),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFeedbackIcon(String type) {
    switch (type) {
      case 'Bug Report':
        return Icons.bug_report;
      case 'Feature Request':
        return Icons.lightbulb_outline;
      case 'User Experience':
        return Icons.person_outline;
      case 'Performance Issue':
        return Icons.speed;
      case 'Content Issue':
        return Icons.content_paste;
      default:
        return Icons.feedback;
    }
  }
}