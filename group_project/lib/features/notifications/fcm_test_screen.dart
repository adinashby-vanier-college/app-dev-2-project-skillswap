import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_service.dart';
import 'models/notification_model.dart';

/// Screen for testing Firebase Cloud Messaging functionality.
class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({super.key});

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  final FCMService _fcmService = FCMService();
  final NotificationService _notificationService = NotificationService();
  
  String _fcmToken = 'Loading...';
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadFCMInfo();
  }

  Future<void> _loadFCMInfo() async {
    try {
      final token = await _fcmService.getToken();
      final enabled = await _fcmService.areNotificationsEnabled();
      
      setState(() {
        _fcmToken = token ?? 'No token available';
        _notificationsEnabled = enabled;
      });
    } catch (e) {
      setState(() {
        _fcmToken = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test Screen'),
        backgroundColor: theme.cardColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FCM Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _notificationsEnabled 
                              ? Icons.notifications_active 
                              : Icons.notifications_off,
                          color: _notificationsEnabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FCM Status',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notifications: ${_notificationsEnabled ? "Enabled" : "Disabled"}',
                      style: TextStyle(
                        color: _notificationsEnabled ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FCM Token:',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _fcmToken,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _fcmToken));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Token copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Token'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _loadFCMInfo,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Notifications Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Test Notifications',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Test Local Notification
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testLocalNotification,
                        icon: const Icon(Icons.notifications),
                        label: const Text('Test Local Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Test New Match Notification
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testMatchNotification,
                        icon: const Icon(Icons.favorite),
                        label: const Text('Test Match Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Test Message Notification
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testMessageNotification,
                        icon: const Icon(Icons.message),
                        label: const Text('Test Message Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Test Session Reminder
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testSessionReminder,
                        icon: const Icon(Icons.schedule),
                        label: const Text('Test Session Reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Testing Instructions',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Copy the FCM token above\n'
                      '2. Use Firebase Console → Cloud Messaging → "Send test message"\n'
                      '3. Paste the token to send push notifications\n'
                      '4. Test with app in foreground, background, and closed\n'
                      '5. Local test buttons create in-app notifications only\n'
                      '\n'
                      'Note: Push notifications only work on physical devices, not simulators/emulators.',
                      style: TextStyle(height: 1.4),
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

  Future<void> _testLocalNotification() async {
    try {
      await _notificationService.createNotification(
        userId: _notificationService.currentUserId ?? 'test-user',
        title: 'Test Notification 📱',
        body: 'This is a test notification created locally!',
        type: NotificationType.general,
        data: {'test': 'true'},
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Local notification created! Check your notifications screen.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testMatchNotification() async {
    try {
      await _notificationService.notifyNewMatch(
        userId: _notificationService.currentUserId ?? 'test-user',
        matchName: 'John Doe (Test)',
        matchId: 'test-match-123',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💖 Match notification created!'),
          backgroundColor: Colors.pink,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _testMessageNotification() async {
    try {
      await _notificationService.notifyNewMessage(
        userId: _notificationService.currentUserId ?? 'test-user',
        senderName: 'Test User',
        message: 'Hello! This is a test message notification.',
        conversationId: 'test-conversation-123',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💬 Message notification created!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _testSessionReminder() async {
    try {
      final sessionTime = DateTime.now().add(const Duration(hours: 1));
      await _notificationService.notifySessionReminder(
        userId: _notificationService.currentUserId ?? 'test-user',
        partnerName: 'Jane Smith (Test)',
        skill: 'Flutter Development',
        sessionTime: sessionTime,
        sessionId: 'test-session-123',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Session reminder created!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}