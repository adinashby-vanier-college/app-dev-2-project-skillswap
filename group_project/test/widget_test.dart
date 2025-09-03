import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_project/features/settings/settings_screen.dart';
import 'package:group_project/features/settings/help_center_screen.dart';
import 'package:group_project/widgets/chat_bubble.dart';

void main() {
  group('Widget Tests (Firebase-Free)', () {
    testWidgets('Settings screen displays basic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
        ),
      );

      // Verify basic structure exists
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('Help Center displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HelpCenterScreen(),
        ),
      );

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How do I find skill partners?'), findsOneWidget);
    });

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

      expect(find.text('message was deleted'), findsOneWidget);
      expect(find.text('Original message'), findsNothing);
    });
  });

  group('Theme Tests', () {
    testWidgets('Widgets work with light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const SettingsScreen(),
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Widgets work with dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SettingsScreen(),
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Basic Interaction Tests', () {
    testWidgets('Simple button tap works', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      
      await tester.tap(find.byType(ElevatedButton));
      expect(buttonPressed, isTrue);
    });

    testWidgets('Simple text input works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const TextField(
              decoration: InputDecoration(hintText: 'Enter text'),
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
}