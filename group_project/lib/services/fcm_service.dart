import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      debugPrint('FCM Permission granted: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get the token
        _token = await _messaging.getToken();
        debugPrint('FCM Token: $_token');

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
        debugPrint('FCM Permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
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

      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // You can show a local notification here or update UI
    // For now, we'll just log it
  }

  // Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Handle navigation based on message data
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'new_message':
        // Navigate to chat screen
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          // You would navigate to chat screen here
          debugPrint('Navigate to chat: $conversationId');
        }
        break;
      
      case 'new_match':
        // Navigate to matches screen or profile
        final matchId = data['matchId'];
        if (matchId != null) {
          debugPrint('Navigate to match profile: $matchId');
        }
        break;
      
      case 'session_reminder':
        // Navigate to sessions screen
        final sessionId = data['sessionId'];
        if (sessionId != null) {
          debugPrint('Navigate to session: $sessionId');
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
        debugPrint('No FCM token found for user: $toUserId');
        return;
      }

      // In a real app, you would send this to your backend server
      // which would use the Firebase Admin SDK to send the notification
      debugPrint('Would send push notification to token: $fcmToken');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: $data');

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
      debugPrint('Error sending push notification: $e');
    }
  }

  // Subscribe to topic (useful for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
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
      debugPrint('Error checking notification settings: $e');
      return false;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}