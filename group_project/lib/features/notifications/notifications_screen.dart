import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'models/notification_model.dart';
import '../chat/chat_screen.dart';
import '../profile/view_profile_screen.dart';

/// Screen displaying user notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (!mounted || !context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear old notifications',
            onPressed: () async {
              await _notificationService.cleanupOldNotifications();
              if (!mounted || !context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Old notifications cleared')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 153/255),
                    ),
                  ),
                ],
              ),
            );
          }
          
          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 100/255),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 153/255),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when you receive matches, messages, and session updates.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 128/255),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final isUnread = !notification.isRead;
    
    return Card(
      elevation: isUnread ? 4 : 2,
      color: isUnread 
          ? colorScheme.primaryContainer.withValues(alpha: 51/255)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread 
            ? BorderSide(color: colorScheme.primary.withValues(alpha: 102/255), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on notification type
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withValues(alpha: 51/255),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 178/255),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: colorScheme.onSurface.withValues(alpha: 128/255),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 128/255),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _getTypeLabel(notification.type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getTypeColor(notification.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurface.withValues(alpha: 153/255),
                ),
                onSelected: (value) => _handleAction(notification, value),
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 18),
                          SizedBox(width: 8),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newMatch:
        return Icons.favorite;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.sessionProposal:
        return Icons.handshake;
      case NotificationType.sessionReminder:
        return Icons.schedule;
      case NotificationType.skillRequest:
        return Icons.lightbulb;
      case NotificationType.general:
        return Icons.info;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newMatch:
        return Colors.pink;
      case NotificationType.newMessage:
        return Colors.blue;
      case NotificationType.sessionProposal:
        return Colors.green;
      case NotificationType.sessionReminder:
        return Colors.orange;
      case NotificationType.skillRequest:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.newMatch:
        return 'Match';
      case NotificationType.newMessage:
        return 'Message';
      case NotificationType.sessionProposal:
        return 'Session';
      case NotificationType.sessionReminder:
        return 'Reminder';
      case NotificationType.skillRequest:
        return 'Request';
      case NotificationType.general:
        return 'General';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.newMatch:
        final matchId = notification.data['matchId'];
        if (matchId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProfileScreen(userId: matchId),
            ),
          );
        }
        break;

      case NotificationType.newMessage:
        final conversationId = notification.data['conversationId'];
        if (conversationId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversationId: conversationId),
            ),
          );
        }
        break;

      case NotificationType.sessionProposal:
      case NotificationType.sessionReminder:
        final sessionId = notification.data['sessionId'];
        if (sessionId != null) {
          // Navigate to session details or sessions list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session navigation - feature coming soon!')),
          );
        }
        break;

      case NotificationType.skillRequest:
        final requesterId = notification.data['requesterId'];
        if (requesterId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProfileScreen(userId: requesterId),
            ),
          );
        }
        break;

      case NotificationType.general:
        // No specific action for general notifications
        break;
    }
  }

  void _handleAction(NotificationModel notification, String action) async {
    switch (action) {
      case 'mark_read':
        await _notificationService.markAsRead(notification.id);
        break;
      case 'delete':
        await _notificationService.deleteNotification(notification.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
        break;
    }
  }
}