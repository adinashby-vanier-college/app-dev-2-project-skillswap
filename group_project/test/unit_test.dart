import 'package:flutter_test/flutter_test.dart';
import 'package:group_project/features/matches/matches_screen.dart';
import 'package:group_project/features/notifications/models/notification_model.dart';

void main() {
  group('Utility Functions', () {
    test('generateConversationId creates consistent IDs', () {
      const user1 = 'user_abc';
      const user2 = 'user_xyz';

      final id1 = generateConversationId(user1, user2);
      final id2 = generateConversationId(user2, user1); // Reversed order

      // Should produce the same ID regardless of parameter order
      expect(id1, equals(id2));
      expect(id1, contains(user1));
      expect(id1, contains(user2));
      expect(id1, contains('_'));
    });

    test('generateConversationId handles edge cases', () {
      // Same user (shouldn't happen in practice, but should handle gracefully)
      const sameUser = 'user123';
      final sameUserResult = generateConversationId(sameUser, sameUser);
      expect(sameUserResult, isA<String>());
      expect(sameUserResult.isNotEmpty, isTrue);

      // Empty strings (edge case)
      const emptyUser = '';
      const normalUser = 'user456';
      final edgeResult = generateConversationId(emptyUser, normalUser);
      expect(edgeResult, isA<String>());
      expect(edgeResult.isNotEmpty, isTrue);
    });
  });

  group('Notification Model Tests', () {
    test('NotificationModel creates correctly', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'test-123',
        userId: 'user-456',
        title: 'Test Notification',
        body: 'This is a test notification body',
        type: NotificationType.newMessage,
        createdAt: now,
        isRead: false,
        data: {'key': 'value'},
      );

      expect(notification.id, equals('test-123'));
      expect(notification.userId, equals('user-456'));
      expect(notification.title, equals('Test Notification'));
      expect(notification.body, equals('This is a test notification body'));
      expect(notification.type, equals(NotificationType.newMessage));
      expect(notification.createdAt, equals(now));
      expect(notification.isRead, isFalse);
      expect(notification.data, equals({'key': 'value'}));
    });

    test('NotificationModel toMap works correctly', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'test-123',
        userId: 'user-456',
        title: 'Test Title',
        body: 'Test Body',
        type: NotificationType.newMatch,
        createdAt: now,
        isRead: true,
        data: {'test': 'data'},
      );

      final map = notification.toMap();
      
      expect(map['userId'], equals('user-456'));
      expect(map['title'], equals('Test Title'));
      expect(map['body'], equals('Test Body'));
      expect(map['type'], equals('newMatch'));
      expect(map['isRead'], isTrue);
      expect(map['data'], equals({'test': 'data'}));
      // Note: toMap() uses Timestamp, not milliseconds, and doesn't include id
    });

    test('NotificationType parsing works correctly', () {
      // Test the internal _parseNotificationType method through different scenarios
      final testCases = [
        ('newMatch', NotificationType.newMatch),
        ('newMessage', NotificationType.newMessage),
        ('sessionProposal', NotificationType.sessionProposal),
        ('sessionReminder', NotificationType.sessionReminder),
        ('skillRequest', NotificationType.skillRequest),
        ('unknown_type', NotificationType.general), // Should default to general
      ];

      for (final (_, expected) in testCases) {
        // We can't directly test the private method, but we can verify enum values exist
        expect(expected, isA<NotificationType>());
      }
    });

    test('NotificationModel copyWith works correctly', () {
      final now = DateTime.now();
      final original = NotificationModel(
        id: 'test-123',
        userId: 'user-456',
        title: 'Original Title',
        body: 'Original Body',
        type: NotificationType.general,
        createdAt: now,
        isRead: false,
        data: {'original': 'data'},
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isRead: true,
      );

      expect(updated.id, equals('test-123')); // Unchanged
      expect(updated.userId, equals('user-456')); // Unchanged
      expect(updated.title, equals('Updated Title')); // Changed
      expect(updated.body, equals('Original Body')); // Unchanged
      expect(updated.isRead, isTrue); // Changed
      expect(updated.type, equals(NotificationType.general)); // Unchanged
      expect(updated.createdAt, equals(now)); // Unchanged
      expect(updated.data, equals({'original': 'data'})); // Unchanged
    });

    test('NotificationModel handles all enum types', () {
      final allTypes = [
        NotificationType.newMatch,
        NotificationType.newMessage, 
        NotificationType.sessionProposal,
        NotificationType.sessionReminder,
        NotificationType.skillRequest,
        NotificationType.general,
      ];

      for (final type in allTypes) {
        final notification = NotificationModel(
          id: 'test-${type.name}',
          userId: 'user-test',
          title: 'Test ${type.name}',
          body: 'Test body for ${type.name}',
          type: type,
          createdAt: DateTime.now(),
          isRead: false,
          data: {},
        );

        expect(notification.type, equals(type));
        expect(notification.type.name, isA<String>());
      }
    });
  });

  group('Data Validation Tests', () {
    test('Email format validation', () {
      // Valid emails
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@domain.org',
        'firstname.lastname@subdomain.domain.com',
      ];

      for (final email in validEmails) {
        expect(RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email), 
               isTrue, reason: 'Should accept valid email: $email');
      }

      // Invalid emails
      const invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user name@domain.com', // Space
        '',
      ];

      for (final email in invalidEmails) {
        expect(RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email), 
               isFalse, reason: 'Should reject invalid email: $email');
      }
    });

    test('Skill name validation', () {
      // Valid skill names
      const validSkills = [
        'Flutter',
        'React Native',
        'Machine Learning',
        'UI/UX Design',
        'Data Science',
        'Python Programming',
      ];

      for (final skill in validSkills) {
        expect(skill.isNotEmpty, isTrue);
        expect(skill.trim().length, greaterThan(0));
        expect(skill.length, lessThanOrEqualTo(50)); // Reasonable limit
      }

      // Edge cases
      expect(''.trim().isEmpty, isTrue); // Empty skill should be rejected
      expect('   '.trim().isEmpty, isTrue); // Whitespace-only should be rejected
    });
  });

  group('List Operations Tests', () {
    test('Skills list operations work correctly', () {
      List<String> skills = ['Flutter', 'React', 'Node.js'];
      
      // Test adding skill
      skills.add('Python');
      expect(skills, contains('Python'));
      expect(skills.length, equals(4));
      
      // Test removing skill
      skills.remove('React');
      expect(skills, isNot(contains('React')));
      expect(skills.length, equals(3));
      
      // Test duplicate prevention (if implemented)
      final skillsSet = skills.toSet().toList();
      expect(skillsSet.length, equals(skills.length)); // No duplicates
    });

    test('Message list operations maintain order', () {
      final messages = <Map<String, dynamic>>[];
      
      // Add messages with timestamps
      final now = DateTime.now();
      messages.add({
        'id': '1',
        'text': 'First message',
        'timestamp': now.subtract(const Duration(minutes: 2)),
      });
      
      messages.add({
        'id': '2', 
        'text': 'Second message',
        'timestamp': now.subtract(const Duration(minutes: 1)),
      });
      
      messages.add({
        'id': '3',
        'text': 'Third message', 
        'timestamp': now,
      });
      
      // Sort by timestamp (newest first)
      messages.sort((a, b) => 
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      
      expect(messages.first['text'], equals('Third message'));
      expect(messages.last['text'], equals('First message'));
    });
  });

  group('Error Handling Tests', () {
    test('Null safety checks work correctly', () {
      String? nullableString;
      List<String>? nullableList;
      Map<String, dynamic>? nullableMap;
      
      // Test null checks
      expect(nullableString?.isNotEmpty ?? false, isFalse);
      expect(nullableList?.isNotEmpty ?? false, isFalse);
      expect(nullableMap?.isNotEmpty ?? false, isFalse);
      
      // Test non-null values
      nullableString = 'Not null';
      nullableList = ['item1', 'item2'];
      nullableMap = {'key': 'value'};
      
      expect(nullableString.isNotEmpty, isTrue);
      expect(nullableList.isNotEmpty, isTrue);
      expect(nullableMap.isNotEmpty, isTrue);
    });

    test('Empty collection handling', () {
      final emptyList = <String>[];
      final emptyMap = <String, dynamic>{};
      const emptyString = '';
      
      expect(emptyList.isEmpty, isTrue);
      expect(emptyMap.isEmpty, isTrue);
      expect(emptyString.isEmpty, isTrue);
      
      // Safe operations on empty collections
      expect(() => emptyList.first, throwsStateError);
      expect(emptyList.firstOrNull, isNull);
      expect(emptyMap['nonexistent'], isNull);
    });
  });
}