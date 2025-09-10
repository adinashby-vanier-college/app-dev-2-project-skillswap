import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// Service for managing Firebase Cloud Messaging.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _token;

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.fcm('Permission granted: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get the token
        _token = await _messaging.getToken();
        AppLogger.fcm('Token obtained: $_token');

        // Save token to user document in Firestore
        await _saveTokenToFirestore();

        // Handle token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages (when app is in background but not terminated)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle messages when app is launched from terminated state
        FirebaseMessaging.instance.getInitialMessage().then((message) {
          if (message != null) {
            _handleMessageOpenedApp(message);
          }
        });

      } else {
        AppLogger.warn('Permission denied', tag: 'FCM');
      }
    } catch (e) {
      AppLogger.error('Error initializing FCM', tag: 'FCM', error: e);
    }
  }

  // Save FCM token to user document
  Future<void> _saveTokenToFirestore([String? token]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fcmToken = token ?? _token ?? await _messaging.getToken();
      if (fcmToken == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': fcmToken,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.fcm('Token saved to Firestore');
    } catch (e) {
      AppLogger.error('Error saving FCM token', tag: 'FCM', error: e);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.fcm('Received foreground message: ${message.messageId}');
    AppLogger.fcm('Title: ${message.notification?.title}');
    AppLogger.fcm('Body: ${message.notification?.body}');
    AppLogger.fcm('Data: ${message.data}');

    // You can show a local notification here or update UI
    // For now, we'll just log it
  }

  // Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.fcm('Message opened app: ${message.messageId}');
    AppLogger.fcm('Data: ${message.data}');

    // Handle navigation based on message data
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'new_message':
        // Navigate to chat screen
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          // You would navigate to chat screen here
          AppLogger.fcm('Navigate to chat: $conversationId');
        }
        break;
      
      case 'new_match':
        // Navigate to matches screen or profile
        final matchId = data['matchId'];
        if (matchId != null) {
          AppLogger.fcm('Navigate to match profile: $matchId');
        }
        break;
      
      case 'session_reminder':
        // Navigate to sessions screen
        final sessionId = data['sessionId'];
        if (sessionId != null) {
          AppLogger.fcm('Navigate to session: $sessionId');
        }
        break;
    }
  }

  // Send push notification (this would typically be called from your backend)
  Future<void> sendPushNotification({
    required String toUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get the user's FCM token
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken == null) {
        AppLogger.warn('No FCM token found for user: $toUserId', tag: 'FCM');
        return;
      }

      // In a real app, you would send this to your backend server
      // which would use the Firebase Admin SDK to send the notification
      AppLogger.fcm('Would send push notification to token: $fcmToken');
      AppLogger.fcm('Title: $title');
      AppLogger.fcm('Body: $body');
      AppLogger.fcm('Data: $data');

      // For now, we'll just log it since we don't have a backend
      // In production, you would make an HTTP request to your server:
      /*
      final response = await http.post(
        Uri.parse('https://your-backend.com/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data,
        }),
      );
      */

    } catch (e) {
      AppLogger.error('Error sending push notification', tag: 'FCM', error: e);
    }
  }

  // Subscribe to topic (useful for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.fcm('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Error subscribing to topic', tag: 'FCM', error: e);
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.fcm('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Error unsubscribing from topic', tag: 'FCM', error: e);
    }
  }

  // Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.error('Error getting FCM token', tag: 'FCM', error: e);
      return null;
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      AppLogger.error('Error checking notification settings', tag: 'FCM', error: e);
      return false;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.fcm('Handling background message: ${message.messageId}');
  AppLogger.fcm('Title: ${message.notification?.title}');
  AppLogger.fcm('Body: ${message.notification?.body}');
  AppLogger.fcm('Data: ${message.data}');
}