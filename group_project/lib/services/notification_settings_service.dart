import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user notification preferences.
class NotificationSettingsService {
  static final NotificationSettingsService _instance = NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? get currentUserId => _auth.currentUser?.uid;

  // Default notification settings
  static const Map<String, bool> defaultSettings = {
    'newMatchNotifications': true,
    'messageNotifications': true,
    'skillRequestNotifications': true,
    'sessionReminderNotifications': true,
    'sessionProposalNotifications': true,
    'generalNotifications': true,
  };

  // Get user's notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    if (currentUserId == null) return defaultSettings;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      final data = doc.data();
      final settings = data?['notificationSettings'] as Map<String, dynamic>?;

      if (settings == null) {
        // If no settings exist, create default ones
        await setNotificationSettings(defaultSettings);
        return defaultSettings;
      }

      // Merge with defaults to ensure all keys exist
      final result = Map<String, bool>.from(defaultSettings);
      settings.forEach((key, value) {
        if (result.containsKey(key) && value is bool) {
          result[key] = value;
        }
      });

      return result;
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return defaultSettings;
    }
  }

  // Update notification settings
  Future<void> setNotificationSettings(Map<String, bool> settings) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'notificationSettings': settings,
        'settingsUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Notification settings updated: $settings');
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      throw Exception('Failed to update notification settings');
    }
  }

  // Update a single notification setting
  Future<void> updateSetting(String settingKey, bool value) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'notificationSettings.$settingKey': value,
        'settingsUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated $settingKey to $value');
    } catch (e) {
      debugPrint('Error updating setting $settingKey: $e');
      throw Exception('Failed to update notification setting');
    }
  }

  // Check if a specific notification type is enabled
  Future<bool> isNotificationEnabled(String notificationType) async {
    final settings = await getNotificationSettings();
    
    switch (notificationType) {
      case 'newMatch':
        return settings['newMatchNotifications'] ?? true;
      case 'newMessage':
        return settings['messageNotifications'] ?? true;
      case 'skillRequest':
        return settings['skillRequestNotifications'] ?? true;
      case 'sessionReminder':
        return settings['sessionReminderNotifications'] ?? true;
      case 'sessionProposal':
        return settings['sessionProposalNotifications'] ?? true;
      case 'general':
        return settings['generalNotifications'] ?? true;
      default:
        return true; // Default to enabled for unknown types
    }
  }

  // Stream of notification settings
  Stream<Map<String, bool>> getNotificationSettingsStream() {
    if (currentUserId == null) {
      return Stream.value(defaultSettings);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      final settings = data?['notificationSettings'] as Map<String, dynamic>?;

      if (settings == null) {
        return defaultSettings;
      }

      // Merge with defaults
      final result = Map<String, bool>.from(defaultSettings);
      settings.forEach((key, value) {
        if (result.containsKey(key) && value is bool) {
          result[key] = value;
        }
      });

      return result;
    });
  }

  // Enable all notifications
  Future<void> enableAllNotifications() async {
    final allEnabled = Map<String, bool>.from(defaultSettings);
    allEnabled.updateAll((key, value) => true);
    await setNotificationSettings(allEnabled);
  }

  // Disable all notifications
  Future<void> disableAllNotifications() async {
    final allDisabled = Map<String, bool>.from(defaultSettings);
    allDisabled.updateAll((key, value) => false);
    await setNotificationSettings(allDisabled);
  }

  // Get user-friendly setting names
  static Map<String, String> getSettingDisplayNames() {
    return {
      'newMatchNotifications': 'New Match Notifications',
      'messageNotifications': 'Message Notifications',
      'skillRequestNotifications': 'Skill Request Notifications',
      'sessionReminderNotifications': 'Session Reminder Notifications',
      'sessionProposalNotifications': 'Session Proposal Notifications',
      'generalNotifications': 'General Notifications',
    };
  }

  // Get setting descriptions
  static Map<String, String> getSettingDescriptions() {
    return {
      'newMatchNotifications': 'Get notified when you find a new skill exchange match',
      'messageNotifications': 'Get notified when you receive new messages',
      'skillRequestNotifications': 'Get notified when someone wants to learn from you',
      'sessionReminderNotifications': 'Get reminded about upcoming skill exchange sessions',
      'sessionProposalNotifications': 'Get notified about new session proposals',
      'generalNotifications': 'Receive app updates and general announcements',
    };
  }
}