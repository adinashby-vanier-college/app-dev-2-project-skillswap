import 'package:flutter/material.dart';
import '../chat/session_service.dart';

class SessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> session;

  const SessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = session['status'] as String;
    final isVirtual = session['type'] == 'virtual';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
        actions: [
          if (status == 'completed')
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session['title'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isVirtual) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              'Virtual Session',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Card
            _buildInfoCard(
              theme,
              'Date & Time',
              Icons.schedule,
              [
                _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(session['date'])),
                _buildInfoRow(Icons.access_time, 'Time', session['time']),
                _buildInfoRow(Icons.timer, 'Duration', session['duration']),
              ],
            ),
            const SizedBox(height: 12),

            // Location Card
            _buildInfoCard(
              theme,
              'Location',
              isVirtual ? Icons.videocam : Icons.location_on,
              [
                _buildInfoRow(
                  isVirtual ? Icons.computer : Icons.place,
                  isVirtual ? 'Platform' : 'Venue',
                  session['location'],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Skills Card
            _buildInfoCard(
              theme,
              'Skills Covered',
              Icons.school,
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (session['skills'] as List<dynamic>).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skill.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            
            // Rating Card (only for completed sessions)
            if (status == 'completed' && session['rating'] > 0) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                theme,
                'Session Rating',
                Icons.star,
                [
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < session['rating'] ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                      const SizedBox(width: 12),
                      Text(
                        '${session['rating']}/5',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // Notes Card
            if (session['notes'] != null && session['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                theme,
                'Session Notes',
                Icons.note,
                [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session['notes'],
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withAlpha(204),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action Buttons
            const SizedBox(height: 24),
            if (status == 'scheduled') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showCancelDialog(context);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Session'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showRescheduleDialog(context);
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Reschedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'completed') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showBookAgainDialog(context);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Book Similar Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, IconData titleIcon, List<Widget> content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(titleIcon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
                     'July', 'August', 'September', 'October', 'November', 'December'];
      
      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];
      
      return '$weekday, $month ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: const Text('Are you sure you want to cancel this session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Session'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final sessionService = SessionService();
                await sessionService.cancelBookedSession(session['id']);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session cancelled successfully')),
                  );
                  // Go back to previous screen since this session is now cancelled
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel session: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Session'),
        content: const Text('Contact your session partner to reschedule this session to a new time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reschedule feature coming soon!')),
              );
            },
            child: const Text('Contact Partner'),
          ),
        ],
      ),
    );
  }

  void _showBookAgainDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Similar Session'),
        content: const Text('Would you like to book another session similar to this one?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking feature coming soon!')),
              );
            },
            child: const Text('Book Session'),
          ),
        ],
      ),
    );
  }
}