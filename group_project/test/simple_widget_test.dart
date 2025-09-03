import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_project/widgets/chat_bubble.dart';
import 'package:group_project/features/settings/help_center_screen.dart';
import 'package:group_project/features/settings/terms_of_service_screen.dart';
import 'package:group_project/features/settings/privacy_policy_screen.dart';

void main() {
  group('Simple Widget Tests (No Firebase)', () {
    
    testWidgets('Chat bubble displays message correctly', (WidgetTester tester) async {
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

    testWidgets('Chat bubble shows deleted message placeholder', (WidgetTester tester) async {
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

      // Check what text is actually displayed
      await tester.pumpAndSettle();
      
      // The actual deleted message text might be different
      expect(find.textContaining('deleted'), findsOneWidget);
      expect(find.text('Original message'), findsNothing);
    });

    testWidgets('Help Center screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HelpCenterScreen(),
        ),
      );

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How do I find skill partners?'), findsOneWidget);
      expect(find.text('How do I add or edit my skills?'), findsOneWidget);
    });

    testWidgets('Help Center FAQ items expand', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HelpCenterScreen(),
        ),
      );

      // Find and tap an FAQ item
      final faqItem = find.text('How do I find skill partners?');
      expect(faqItem, findsOneWidget);

      await tester.tap(faqItem);
      await tester.pumpAndSettle();

      // Should show the answer
      expect(find.textContaining('search'), findsOneWidget);
    });

    testWidgets('Terms of Service screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TermsOfServiceScreen(),
        ),
      );

      expect(find.text('SkillSwap Terms of Service'), findsOneWidget);
      expect(find.text('Last updated: January 2025'), findsOneWidget);
      expect(find.text('Acceptance of Terms'), findsOneWidget);
    });

    testWidgets('Privacy Policy screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyPolicyScreen(),
        ),
      );

      expect(find.text('SkillSwap Privacy Policy'), findsOneWidget);
      expect(find.text('Last updated: January 2025'), findsOneWidget);
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Information We Collect'), findsOneWidget);
    });

    testWidgets('Widgets work with different themes', (WidgetTester tester) async {
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
  });

  group('Button and Interaction Tests', () {
    testWidgets('Buttons are tappable and respond', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  buttonPressed = true;
                },
                child: const Text('Test Button'),
              ),
            ),
          ),
        ),
      );

      final button = find.text('Test Button');
      expect(button, findsOneWidget);

      await tester.tap(button);
      expect(buttonPressed, isTrue);
    });

    testWidgets('Text input works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const TextField(
              decoration: InputDecoration(
                hintText: 'Enter text here',
              ),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Test input');
      expect(find.text('Test input'), findsOneWidget);
    });
  });

  group('Form Validation Tests', () {
    testWidgets('Form validation works', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Field is required';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState?.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Try to validate empty form
      await tester.tap(find.text('Validate'));
      await tester.pump();

      expect(find.text('Field is required'), findsOneWidget);
    });
  });
}