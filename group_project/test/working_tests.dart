import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_project/features/matches/matches_screen.dart';
import 'package:group_project/features/notifications/models/notification_model.dart';
import 'package:group_project/widgets/chat_bubble.dart';
import 'package:group_project/features/settings/help_center_screen.dart';
import 'package:group_project/features/settings/terms_of_service_screen.dart';
import 'package:group_project/features/settings/privacy_policy_screen.dart';
import 'package:group_project/features/settings/send_feedback_screen.dart';

void main() {
  group('Working Unit Tests', () {
    test('generateConversationId creates consistent IDs', () {
      const user1 = 'user_abc';
      const user2 = 'user_xyz';

      final id1 = generateConversationId(user1, user2);
      final id2 = generateConversationId(user2, user1);

      expect(id1, equals(id2));
      expect(id1, contains(user1));
      expect(id1, contains(user2));
      expect(id1, contains('_'));
    });

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

    test('Email format validation with proper regex', () {
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@domain.org',
        'firstname.lastname@subdomain.domain.com',
      ];

      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

      for (final email in validEmails) {
        expect(emailRegex.hasMatch(email), isTrue, reason: 'Should accept valid email: $email');
      }

      const invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user name@domain.com',
        '',
      ];

      for (final email in invalidEmails) {
        expect(emailRegex.hasMatch(email), isFalse, reason: 'Should reject invalid email: $email');
      }
    });

    test('List operations work correctly', () {
      List<String> skills = ['Flutter', 'React', 'Node.js'];
      
      skills.add('Python');
      expect(skills, contains('Python'));
      expect(skills.length, equals(4));
      
      skills.remove('React');
      expect(skills, isNot(contains('React')));
      expect(skills.length, equals(3));
    });
  });

  group('Working Widget Tests', () {
    testWidgets('Chat bubble displays message', (WidgetTester tester) async {
      const testMessage = 'Hello, this is a test message!';
      final testTime = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: testMessage,
              isMe: true,
              timestamp: testTime,
              senderName: 'Test User',
            ),
          ),
        ),
      );

      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('Deleted chat bubble shows correct text', (WidgetTester tester) async {
      final testTime = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'Original message',
              isMe: true,
              timestamp: testTime,
              isDeleted: true,
              senderName: 'Test User',
            ),
          ),
        ),
      );

      // Based on the actual code, it shows "message was deleted"
      expect(find.text('message was deleted'), findsOneWidget);
      expect(find.text('Original message'), findsNothing);
    });

    testWidgets('Help Center displays FAQ items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HelpCenterScreen(),
        ),
      );

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How do I find skill partners?'), findsOneWidget);
      expect(find.text('How do I add or edit my skills?'), findsOneWidget);
    });

    testWidgets('FAQ items are expandable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HelpCenterScreen(),
        ),
      );

      final faqItem = find.text('How do I find skill partners?');
      expect(faqItem, findsOneWidget);

      await tester.tap(faqItem);
      await tester.pumpAndSettle();

      expect(find.textContaining('search feature'), findsOneWidget);
    });

    testWidgets('Terms of Service displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TermsOfServiceScreen(),
        ),
      );

      expect(find.text('SkillSwap Terms of Service'), findsOneWidget);
      expect(find.text('Acceptance of Terms'), findsOneWidget);
      expect(find.text('Description of Service'), findsOneWidget);
    });

    testWidgets('Privacy Policy displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyPolicyScreen(),
        ),
      );

      expect(find.text('SkillSwap Privacy Policy'), findsOneWidget);
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Information We Collect'), findsOneWidget);
    });

    testWidgets('Send Feedback form displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SendFeedbackScreen(),
        ),
      );

      expect(find.text('We value your feedback!'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('Themes work correctly', (WidgetTester tester) async {
      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const HelpCenterScreen(),
        ),
      );

      expect(find.byType(HelpCenterScreen), findsOneWidget);

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HelpCenterScreen(),
        ),
      );

      expect(find.byType(HelpCenterScreen), findsOneWidget);
    });

    testWidgets('Simple form interaction works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(hintText: 'Enter text'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      final button = find.text('Submit');

      expect(textField, findsOneWidget);
      expect(button, findsOneWidget);

      await tester.enterText(textField, 'Test input');
      expect(find.text('Test input'), findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      // No errors should occur
    });
  });

  group('Error Handling Tests', () {
    test('Null safety works correctly', () {
      String? nullableString;
      List<String>? nullableList;
      
      expect(nullableString?.isNotEmpty ?? false, isFalse);
      expect(nullableList?.isNotEmpty ?? false, isFalse);
      
      nullableString = 'Not null';
      nullableList = ['item1'];
      
      expect(nullableString.isNotEmpty, isTrue);
      expect(nullableList.isNotEmpty, isTrue);
    });

    test('Empty collection handling', () {
      final emptyList = <String>[];
      final emptyMap = <String, dynamic>{};
      
      expect(emptyList.isEmpty, isTrue);
      expect(emptyMap.isEmpty, isTrue);
      
      expect(() => emptyList.first, throwsStateError);
      expect(emptyMap['nonexistent'], isNull);
    });
  });
}