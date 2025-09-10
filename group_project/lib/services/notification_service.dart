import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/notifications/models/notification_model.dart';
import 'fcm_service.dart';
import 'notification_settings_service.dart';

/// Service for managing user notifications and push messages.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();
  final NotificationSettingsService _settingsService = NotificationSettingsService();
  
  String? get currentUserId => _auth.currentUser?.uid;

  /// Creates a notification in Firestore and sends push notification if enabled.
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    if (currentUserId == null) return;

    // Check if the user has this notification type enabled
    final isEnabled = await _settingsService.isNotificationEnabled(type.name);
    if (!isEnabled) {
      debugPrint('Notification type ${type.name} is disabled for user $userId');
      return; // Don't send notification if disabled
    }

    final notification = NotificationModel(
      id: '', // Firestore will generate this
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data ?? {},
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('notifications')
        .add(notification.toMap());

    // Send push notification via FCM
    await _fcmService.sendPushNotification(
      toUserId: userId,
      title: title,
      body: body,
      data: {
        'type': type.name,
        'notificationId': notification.id,
        ...notification.data.map((k, v) => MapEntry(k, v.toString())),
      },
    );
  }

  // Get notifications stream for current user
  Stream<List<NotificationModel>> getNotifications() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final unreadNotifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Get unread count
  Stream<int> getUnreadCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Notification creators for different types
  Future<void> notifyNewMatch({
    required String userId,
    required String matchName,
    required String matchId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Match Found! 🎉',
      body: 'You have a new match with $matchName. Start exchanging skills!',
      type: NotificationType.newMatch,
      data: {
        'matchId': matchId,
        'matchName': matchName,
      },
    );
  }

  Future<void> notifyNewMessage({
    required String userId,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New message from $senderName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: NotificationType.newMessage,
      data: {
        'conversationId': conversationId,
        'senderName': senderName,
      },
    );
  }

  Future<void> notifySessionProposal({
    required String userId,
    required String proposerName,
    required String skill,
    required String proposalId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Session Proposal 📚',
      body: '$proposerName wants to exchange skills in $skill',
      type: NotificationType.sessionProposal,
      data: {
        'proposalId': proposalId,
        'proposerName': proposerName,
        'skill': skill,
      },
    );
  }

  Future<void> notifySessionReminder({
    required String userId,
    required String partnerName,
    required String skill,
    required DateTime sessionTime,
    required String sessionId,
  }) async {
    final timeStr = _formatSessionTime(sessionTime);
    await createNotification(
      userId: userId,
      title: 'Session Reminder ⏰',
      body: 'Your $skill session with $partnerName starts $timeStr',
      type: NotificationType.sessionReminder,
      data: {
        'sessionId': sessionId,
        'partnerName': partnerName,
        'skill': skill,
        'sessionTime': sessionTime.toIso8601String(),
      },
    );
  }

  Future<void> notifySkillRequest({
    required String userId,
    required String requesterName,
    required String skill,
    required String requestId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Skill Request 💡',
      body: '$requesterName is interested in learning $skill from you',
      type: NotificationType.skillRequest,
      data: {
        'requestId': requestId,
        'requesterName': requesterName,
        'skill': skill,
      },
    );
  }

  // Helper method to format session time
  String _formatSessionTime(DateTime sessionTime) {
    final now = DateTime.now();
    final difference = sessionTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'now';
    }
  }

  // Schedule session reminders (to be called when sessions are created)
  Future<void> scheduleSessionReminders({
    required String sessionId,
    required List<String> participants,
    required String skill,
    required DateTime sessionTime,
  }) async {
    // Schedule reminders for 24 hours before
    final oneDayBefore = sessionTime.subtract(const Duration(days: 1));

    if (oneDayBefore.isAfter(DateTime.now())) {
      // In a real app, you'd use a background job scheduler
      // For now, we'll create future notifications
      for (String userId in participants) {
        if (userId != currentUserId) {
          // Get participant name
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final userName = userDoc.data()?['name'] ?? 'Unknown';
          
          await notifySessionReminder(
            userId: userId,
            partnerName: userName,
            skill: skill,
            sessionTime: sessionTime,
            sessionId: sessionId,
          );
        }
      }
    }
  }

  // Clean up old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    if (currentUserId == null) return;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final oldNotifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    final batch = _firestore.batch();
    for (var doc in oldNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}